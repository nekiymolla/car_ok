import { InjectPubSub } from '@nestjs-query/query-graphql';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DriverStatus } from '@ridy/database/enums/driver-status.enum';
import { OrderStatus } from '@ridy/database/enums/order-status.enum';
import { RequestActivityType } from '@ridy/database/enums/request-activity-type.enum';
import { RequestActivityEntity } from '@ridy/database/request-activity.entity';
import { RequestEntity } from '@ridy/database/request.entity';
import { SharedDriverService } from '@ridy/order/shared-driver.service';
import { OrderRedisService } from '@ridy/redis/order-redis.service';
import { ForbiddenError } from 'apollo-server-core';
import { RedisPubSub } from 'graphql-redis-subscriptions';
import { Repository } from 'typeorm';

@Injectable()
export class OrderService {
    constructor(
        @InjectRepository(RequestEntity)
        public orderRepository: Repository<RequestEntity>,
        @InjectRepository(RequestActivityEntity)
        public activityRepository: Repository<RequestActivityEntity>,
        private driverService: SharedDriverService,        
        private orderRedisService: OrderRedisService,
        @InjectPubSub()
        private pubSub: RedisPubSub,
    ) { }

    async cancelOrder(orderId: number): Promise<RequestEntity> {
        let order = await this.orderRepository.findOne(orderId);
        const allowedStatuses = [OrderStatus.DriverAccepted, OrderStatus.Arrived];
        if (order == null || !allowedStatuses.includes(order.status)) {
            throw new ForbiddenError("It is not allowed to cancel this order");
        }
        await this.orderRepository.update(order.id, { status: OrderStatus.DriverCanceled, finishTimestamp: new Date(), costAfterCoupon: 0 });
        order = await this.orderRepository.findOne(order.id);
        this.driverService.updateDriverStatus(order.driverId, DriverStatus.Online);
        this.pubSub.publish('orderUpdated', { orderUpdated: order });
        return order;
    }
    
    async expireOrders(orderIds: number[]) {
        this.orderRedisService.expire(orderIds);
        this.orderRepository.update(orderIds, { status: OrderStatus.Expired });
        for(const requestId of orderIds) {
            this.activityRepository.insert({
                requestId,
                type: RequestActivityType.Expired
            });
        }
        
        
    }
}