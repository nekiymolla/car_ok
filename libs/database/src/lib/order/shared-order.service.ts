import { InjectPubSub } from '@nestjs-query/query-graphql';
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DriverDeductTransactionType } from '@ridy/database/enums/driver-deduct-transaction-type.enum';
import { DriverRechargeTransactionType } from '@ridy/database/enums/driver-recharge-transaction-type.enum';
import { DriverStatus } from '@ridy/database/enums/driver-status.enum';
import { ProviderRechargeTransactionType } from '@ridy/database/enums/provider-recharge-transaction-type.enum';
import { RequestActivityType } from '@ridy/database/enums/request-activity-type.enum';
import { RiderDeductTransactionType } from '@ridy/database/enums/rider-deduct-transaction-type.enum';
import { ServicePaymentMethod } from '@ridy/database/enums/service-payment-method.enum';
import { TransactionAction } from '@ridy/database/enums/transaction-action.enum';
import { TransactionStatus } from '@ridy/database/enums/transaction-status.enum';
import { RequestActivityEntity } from '@ridy/database/request-activity.entity';
import { ForbiddenError } from 'apollo-server-fastify';
import { RedisPubSub } from 'graphql-redis-subscriptions';
import { Repository } from 'typeorm';

import { OrderStatus } from '../entities/enums/order-status.enum';
import { RequestEntity } from '../entities/request.entity';
import { ServiceCategoryEntity } from '../entities/service-category.entity';
import { Point } from '../interfaces/point';
import { DriverLocationWithId, DriverRedisService } from '../redis/driver-redis.service';
import { OrderRedisService } from '../redis/order-redis.service';
import { DriverNotificationService } from './firebase-notification-service/driver-notification.service';
import { RiderNotificationService } from './firebase-notification-service/rider-notification.service';
import { GoogleServicesService } from './google-services/google-services.service';
import { RegionService } from './region/region.service';
import { ServiceService } from './service.service';
import { SharedDriverService } from './shared-driver.service';
import { SharedFleetService } from './shared-fleet.service';
import { SharedProviderService } from './shared-provider.service';
import { SharedRiderService } from './shared-rider.service';

@Injectable()
export class SharedOrderService {
    constructor(
        @InjectRepository(RequestEntity)
        private orderRepository: Repository<RequestEntity>,
        @InjectRepository(RequestActivityEntity)
        private activityRepository: Repository<RequestActivityEntity>,
        private regionService: RegionService,
        @InjectRepository(ServiceCategoryEntity)
        private serviceCategoryRepository: Repository<ServiceCategoryEntity>,
        private googleServices: GoogleServicesService,
        private servicesService: ServiceService,
        private riderService: SharedRiderService,
        private driverRedisService: DriverRedisService,
        private orderRedisService: OrderRedisService,
        private driverService: SharedDriverService,
        private sharedProviderService: SharedProviderService,
        private sharedFleetService: SharedFleetService,
        @InjectPubSub()
        private pubSub: RedisPubSub,
        private driverNotificationService: DriverNotificationService,
        private riderNotificationService: RiderNotificationService
    ) { }

    async calculateFare(input: { points: Point[], twoWay: boolean }) {
        const regions = await this.regionService.getRegionWithPoint(input.points[0]);
        if (regions.length < 1) {
            throw new ForbiddenError(CalculateFareError.RegionUnsupported);
        }
        const servicesInRegion = await this.regionService.getRegionServices(regions[0].id);
        if (servicesInRegion.length < 1) {
            throw new ForbiddenError(CalculateFareError.NoServiceInRegion);
        }
        if(input.twoWay && input.points.length > 1) {
            input.points.push(input.points[0]);
        }
        const metrics = (servicesInRegion.findIndex(x => x.perHundredMeters > 0) > -1) ?
            await this.googleServices.getSumDistanceAndDuration(input.points) :
            { distance: 0, duration: 0 };
        const cats = await this.serviceCategoryRepository.find({ relations: ['services', 'services.media'] });
        const _cats = cats.map(cat => {
            const { services, ..._cat } = cat;
            const _services = services.filter(x => servicesInRegion.filter(y => y.id == x.id).length > 0).map(service => {
                return {
                    ...service,
                    cost: this.servicesService.calculateCost(service, metrics.distance, metrics.duration)
                }
            });
            return {
                ..._cat,
                services: _services
            }
        }).filter(x => x.services.length > 0);
        return {
            ...metrics,
            currency: regions[0].currency,
            services: _cats
        }
    }

    async createOrder(input: { riderId: number, serviceId: number, intervalMinutes: number, points: Point[], addresses: string[], operatorId?: number, twoWay: boolean }): Promise<RequestEntity> {
        const service = await this.servicesService.getWithId(input.serviceId);
        if (service == undefined) {
            throw new ForbiddenError('SERVICE_NOT_FOUND');
        }
        const closeDrivers = await this.driverRedisService.getClose(input.points[0], service.searchRadius);
        const driverIds = closeDrivers.map((x: DriverLocationWithId) => x.driverId);
        const fleetIdsInPoint = await this.sharedFleetService.getFleetIdsInPoint(input.points[0]);
        const driversWithService = await this.driverService.getOnlineDriversWithServiceId(driverIds, input.serviceId, fleetIdsInPoint);
        if(input.twoWay && input.points.length > 1) {
            input.points.push(input.points[0]);
        }
        const metrics = service.perHundredMeters > 0 ?
            await this.googleServices.getSumDistanceAndDuration(input.points) :
            { distance: 0, duration: 0 };
        const cost = this.servicesService.calculateCost(service, metrics.distance, metrics.duration);
        const eta = new Date(new Date().getTime() + ((input.intervalMinutes | 0) * 60 * 1000));
        const regions = await this.regionService.getRegionWithPoint(input.points[0]);
        if (service.maximumDestinationDistance != 0 && metrics.distance > service.maximumDestinationDistance) {
            throw new ForbiddenError('DISTANCE_TOO_FAR');
        }
        if (service.prepayPercent > 0) {
            const balance = await this.riderService.getRiderCreditInCurrency(input.riderId, regions[0].currency);
            if (balance < (cost * service.prepayPercent / 100)) {
                throw new ForbiddenError('UNSUFFICIENT_CREDIT');
            }
        }
        const order = await this.orderRepository.save({
            serviceId: input.serviceId,
            currency: regions[0].currency,
            riderId: input.riderId,
            points: input.points,
            addresses: input.addresses.map(address => address.replace(', ', '-')),
            distanceBest: metrics.distance,
            durationBest: metrics.duration,
            status: input.intervalMinutes > 30 ? OrderStatus.Booked : (driversWithService.length < 1 ? OrderStatus.NoCloseFound : OrderStatus.Requested),
            costBest: cost,
            costAfterCoupon: cost,
            expectedTimestamp: eta,
            operatorId: input.operatorId,
            providerShare: service.providerShareFlat + (service.providerSharePercent * cost / 100),
        });
        let activityType = RequestActivityType.RequestedByRider;
        if (input.intervalMinutes > 0) {
            activityType = input.operatorId == null ? activityType = RequestActivityType.BookedByRider : RequestActivityType.BookedByOperator;
        } else {
            activityType = input.operatorId == null ? activityType = RequestActivityType.RequestedByRider : RequestActivityType.RequestedByOperator;
        }
        this.activityRepository.insert({ requestId: order.id, type: activityType });
        await this.orderRedisService.add({...order, fleetIds: fleetIdsInPoint}, input.intervalMinutes | 0);
        if (input.intervalMinutes == null || input.intervalMinutes < 30) {
            for (const driver of driversWithService) {
                this.orderRedisService.driverNotified(order.id, driver.id);
            }
            Logger.log(`publish: ${JSON.stringify(order)}`)
            this.pubSub.publish('orderCreated', { orderCreated: order, driverIds: driversWithService.map(driver => driver.id) });
            const _drivers = driversWithService.filter(x => x.notificationPlayerId != null)
            if (_drivers.length > 0) {
                this.driverNotificationService.requests(_drivers);
            }
        }
        return order;
    }

    async finish(orderId: number, cashAmount = 0.0) {
        const order: RequestEntity = (await this.orderRepository.findOne(orderId, { relations: ['service', 'driver', 'driver.fleet', 'rider'] }))!;
        if (order.service.paymentMethod == ServicePaymentMethod.OnlyCredit && cashAmount > 0) {
            throw new ForbiddenError('Cash payment is not available for this service.');
        }
        const riderCredit = await this.riderService.getRiderCreditInCurrency(order.riderId, order.currency);
        const providerPercent = (order.rider.isResident === false) ? (order.service.providerSharePercent * 1.65) : order.service.providerSharePercent;
        const commission = (providerPercent * order.costAfterCoupon / 100) + order.service.providerShareFlat;
        const unPaidAmount = order.costAfterCoupon - order.paidAmount;
        if ((riderCredit + cashAmount) < unPaidAmount) {
            await this.orderRepository.update(order.id, { status: OrderStatus.WaitingForPostPay });
            return;
        }
        await this.driverService.rechargeWallet({
            status: TransactionStatus.Done,
            driverId: order.driverId!,
            currency: order.currency,
            action: TransactionAction.Deduct,
            deductType: DriverDeductTransactionType.Commission,
            amount: -1 * commission,
            requestId: order.id
        });
        let fleetShare = 0;
        if (order.driver?.fleetId != null) {
            fleetShare = (commission * order.driver.fleet!.commissionSharePercent / 100) + order.driver.fleet!.commissionShareFlat;
            if (fleetShare > 0) {
                this.sharedFleetService.rechargeWallet({
                    fleetId: order.driver.fleetId,
                    action: TransactionAction.Recharge,
                    rechargeType: ProviderRechargeTransactionType.Commission,
                    amount: fleetShare,
                    currency: order.currency
                })
            }
        }
        await this.sharedProviderService.rechargeWallet({
            action: TransactionAction.Recharge,
            rechargeType: ProviderRechargeTransactionType.Commission,
            currency: order.currency,
            amount: commission - fleetShare
        });
        if (order.costAfterCoupon - cashAmount > 0) {
            await this.driverService.rechargeWallet({
                status: TransactionStatus.Done,
                driverId: order.driverId!,
                currency: order.currency,
                action: TransactionAction.Recharge,
                rechargeType: DriverRechargeTransactionType.OrderFee,
                amount: (order.costAfterCoupon - cashAmount)
            });
        }
        if (riderCredit > 0 && cashAmount < unPaidAmount) {
            await this.riderService.rechargeWallet({
                status: TransactionStatus.Done,
                action: TransactionAction.Deduct,
                deductType: RiderDeductTransactionType.OrderFee,
                currency: order.currency,
                amount: -1 * (unPaidAmount - cashAmount),
                riderId: order.riderId
            });
        }
        await this.orderRepository.update(order.id, { paidAmount: order.costAfterCoupon, status: OrderStatus.WaitingForReview, finishTimestamp: new Date() });
        await this.driverService.updateDriverStatus(order.driverId!, DriverStatus.Online);
        this.activityRepository.insert({
            requestId: order.id,
            type: RequestActivityType.Paid
        });
    }

    async assignOrderToDriver(orderId: number, driverId: number) {
        const [travel, driverLocation] = await Promise.all([
            this.orderRepository.findOne(orderId),
            this.driverRedisService.getDriverCoordinate(driverId)
        ]);
        this.activityRepository.insert({
            requestId: orderId,
            type: RequestActivityType.DriverAccepted
        });
        const allowedStatuses = [OrderStatus.Found, OrderStatus.NoCloseFound, OrderStatus.Requested, OrderStatus.Booked];
        if (travel == null || !allowedStatuses.includes(travel.status)) {
            throw new ForbiddenError("Already Taken");
        }
        const metrics = driverLocation != null ? await this.googleServices.getSumDistanceAndDuration([travel.points[0], driverLocation]) : { distance: 0, duration: 0 };
        const dt = new Date();
        const etaPickup = dt.setSeconds(dt.getSeconds() + metrics.duration);
        this.driverService.updateDriverStatus(driverId, DriverStatus.InService);
        //const order = await this.orderRepository.findOne(travel.id);
        await this.orderRedisService.expire([orderId]);
        this.orderRepository.update(orderId, {status: OrderStatus.DriverAccepted, etaPickup: new Date(etaPickup), driverId});
        const result = await this.orderRepository.findOneOrFail(orderId, { relations: ['driver', 'driver.car', 'driver.carColor', 'service']});
        this.pubSub.publish('orderUpdated', { orderUpdated: result });
        this.pubSub.publish('orderRemoved', { orderRemoved: result }); // This one has a filter to let know all except the one accepted.
        this.riderNotificationService.accepted(result.rider);
        return result;
    }

}

enum CalculateFareError {
    RegionUnsupported = 'REGION_UNSUPPORTED',
    NoServiceInRegion = 'NO_SERVICE_IN_REGION'
}