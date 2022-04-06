import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../graphql/generated/graphql_api.dart';

// Events
abstract class MainBlocEvent {}

class AddPoint extends MainBlocEvent {
  SelectedPoint point;

  AddPoint({required this.point});
}

class DropLastPoint extends MainBlocEvent {}

class MapMoved extends MainBlocEvent {
  LatLng latlng;

  MapMoved(this.latlng);
}

class ResetState extends MainBlocEvent {}

class DriverLocationUpdatedEvent extends MainBlocEvent {
  PointMixin location;

  DriverLocationUpdatedEvent(this.location);
}

class ShowPreview extends MainBlocEvent {
  List<SelectedPoint> points;
  bool twoWay;

  ShowPreview({required this.points, required this.twoWay});
}

class SelectService extends MainBlocEvent {
  String serviceId;

  SelectService(this.serviceId);
}

class SelectBookingTime extends MainBlocEvent {
  TimeOfDay time;

  SelectBookingTime(this.time);
}

class ProfileUpdated extends MainBlocEvent {
  GetCurrentOrder$Query$Rider profile;
  PointMixin? driverLocation;

  ProfileUpdated({required this.profile, this.driverLocation});
}

class VersionStatusEvent extends MainBlocEvent {
  VersionStatus status;
  VersionStatusEvent(this.status);
}

class CurrentOrderUpdated extends MainBlocEvent {
  CurrentOrderMixin order;
  PointMixin? driverLocation;

  CurrentOrderUpdated(this.order, {this.driverLocation});
}

class SetDriversLocations extends MainBlocEvent {
  List<LatLng> driversLocations;

  SetDriversLocations(this.driversLocations);
}

// States
abstract class MainBlocState {
  List<MarkerData> markers;
  bool isInteractive;
  int bookedOrdersCount;

  MainBlocState(
      {required this.isInteractive,
      required this.markers,
      this.bookedOrdersCount = 0});
}

class RequireUpdateState extends MainBlocState {
  RequireUpdateState() : super(isInteractive: false, markers: []);
}

class SelectingPoints extends MainBlocState {
  List<SelectedPoint> points = [];
  List<LatLng> driverLocations = [];
  bool loadDrivers;
  int bookingsCount = 0;

  SelectingPoints(this.points, this.driverLocations, this.loadDrivers,
      {this.bookingsCount = 0})
      : super(
            isInteractive: true,
            markers: points
                .take(1)
                .map((e) => MarkerData(e.point.latitude.toString(), e.point,
                    'images/marker_pickup.png', MarkerType.pickup))
                .followedBy(points.skip(1).map((e) => MarkerData(
                    e.point.latitude.toString(),
                    e.point,
                    'images/marker_destination.png',
                    MarkerType.destination)))
                .followedBy(driverLocations
                    .map((e) => MarkerData(e.latitude.toString(), e,
                        'images/marker_taxi.png', MarkerType.driver))
                    .toList())
                .toList());
}

class OrderPreview extends MainBlocState {
  List<SelectedPoint> points = [];
  bool twoWay = false;
  String? selectedService;
  TimeOfDay? selectedTime;

  OrderPreview(this.points, this.twoWay,
      {this.selectedService, this.selectedTime})
      : super(
            isInteractive: false,
            markers: points
                .take(1)
                .map((e) => MarkerData(e.point.latitude.toString(), e.point,
                    'images/marker_pickup.png', MarkerType.pickup))
                .followedBy(points.skip(1).map((e) => MarkerData(
                    e.point.latitude.toString(),
                    e.point,
                    'images/marker_destination.png',
                    MarkerType.destination)))
                .toList());
}

class StateWithActiveOrder extends MainBlocState {
  CurrentOrderMixin currentOrder;
  List<MarkerData> orderMarkers;

  StateWithActiveOrder(this.currentOrder, {this.orderMarkers = const []})
      : super(isInteractive: false, markers: orderMarkers);
}

class OrderLooking extends StateWithActiveOrder {
  CurrentOrderMixin order;

  OrderLooking(this.order) : super(order);
}

class OrderInProgress extends StateWithActiveOrder {
  CurrentOrderMixin order;
  LatLng? driverLocation;

  OrderInProgress(this.order, {this.driverLocation}) : super(order) {
    switch (order.status) {
      case OrderStatus.driverAccepted:
      case OrderStatus.arrived:
        markers = [
          MarkerData(
              order.points[0].lat.toString(),
              LatLng(order.points[0].lat, order.points[0].lng),
              'images/marker_pickup.png',
              MarkerType.pickup)
        ];
        break;

      case OrderStatus.started:
        markers = order.points
            .sublist(1)
            .map((point) => MarkerData(
                point.lat.toString(),
                LatLng(point.lat, point.lng),
                'images/marker_destination.png',
                MarkerType.destination))
            .toList();
        break;

      default:
    }
    if (driverLocation != null) {
      markers.add(MarkerData(driverLocation!.latitude.toString(),
          driverLocation!, 'images/marker_taxi.png', MarkerType.driver));
    }
  }
}

class OrderInvoice extends StateWithActiveOrder {
  CurrentOrderMixin order;

  OrderInvoice(this.order) : super(order);
}

class OrderReview extends StateWithActiveOrder {
  CurrentOrderMixin order;

  OrderReview(this.order) : super(order);
}

class MainBloc extends Bloc<MainBlocEvent, MainBlocState> {
  MainBloc() : super(SelectingPoints([], [], true)) {
    on<VersionStatusEvent>(((event, emit) => emit(RequireUpdateState())));

    on<AddPoint>((event, emit) => emit(SelectingPoints(
        (state as SelectingPoints).points.followedBy([event.point]).toList(),
        (state as SelectingPoints).driverLocations,
        false)));

    on<DropLastPoint>((event, emit) {
      (state as SelectingPoints).points.removeLast();
      emit(SelectingPoints((state as SelectingPoints).points,
          (state as SelectingPoints).driverLocations, false));
    });

    on<MapMoved>((event, emit) {
      if (state is! SelectingPoints) return;
      emit(SelectingPoints((state as SelectingPoints).points, [], true,
          bookingsCount: (state as SelectingPoints).bookingsCount));
    });

    on<ResetState>((event, emit) => emit(SelectingPoints([], [], true)));

    on<ShowPreview>(
        (event, emit) => emit(OrderPreview(event.points, event.twoWay)));

    on<SelectService>((event, emit) => emit(OrderPreview(
        (state as OrderPreview).points, (state as OrderPreview).twoWay,
        selectedTime: (state as OrderPreview).selectedTime,
        selectedService: event.serviceId)));

    on<SelectBookingTime>((event, emit) => emit(OrderPreview(
        (state as OrderPreview).points, (state as OrderPreview).twoWay,
        selectedTime: event.time,
        selectedService: (state as OrderPreview).selectedService)));

    on<ProfileUpdated>((event, emit) {
      LatLng? driverLocation = event.driverLocation != null
          ? LatLng(event.driverLocation!.lat, event.driverLocation!.lng)
          : null;
      if (driverLocation == null &&
          state is OrderInProgress &&
          (state as OrderInProgress).driverLocation != null) {
        driverLocation = (state as OrderInProgress).driverLocation;
      }
      int bookings = event.profile.bookedOrders.first.count?.id ?? 0;
      if (event.profile.orders.isEmpty) {
        emit(SelectingPoints([], [], true, bookingsCount: bookings));
        return;
      }
      GetCurrentOrder$Query$Rider$Order order = event.profile.orders.first;
      switch (order.status) {
        case OrderStatus.requested:
        case OrderStatus.notFound:
        case OrderStatus.noCloseFound:
        case OrderStatus.found:
        case OrderStatus.booked:
          emit(OrderLooking(order));
          return;

        case OrderStatus.driverAccepted:
        case OrderStatus.arrived:
        case OrderStatus.started:
        case OrderStatus.waitingForPrePay:
          emit(OrderInProgress(order, driverLocation: driverLocation));
          return;

        case OrderStatus.expired:
        case OrderStatus.finished:
        case OrderStatus.riderCanceled:
        case OrderStatus.driverCanceled:
        case OrderStatus.artemisUnknown:
          emit(SelectingPoints([], [], true, bookingsCount: bookings));
          return;

        case OrderStatus.waitingForPostPay:
          emit(OrderInvoice(order));
          return;

        case OrderStatus.waitingForReview:
          emit(OrderReview(order));
          return;
      }
    });

    on<CurrentOrderUpdated>(((event, emit) {
      LatLng? driverLocation = event.driverLocation != null
          ? LatLng(event.driverLocation!.lat, event.driverLocation!.lng)
          : null;
      if (driverLocation == null &&
          state is OrderInProgress &&
          (state as OrderInProgress).driverLocation != null) {
        driverLocation = (state as OrderInProgress).driverLocation;
      }
      switch (event.order.status) {
        case OrderStatus.requested:
        case OrderStatus.notFound:
        case OrderStatus.noCloseFound:
        case OrderStatus.found:
        case OrderStatus.booked:
          emit(OrderLooking(event.order));
          return;

        case OrderStatus.driverAccepted:
        case OrderStatus.arrived:
        case OrderStatus.started:
        case OrderStatus.waitingForPrePay:
          emit(OrderInProgress(event.order, driverLocation: driverLocation));
          return;

        case OrderStatus.expired:
        case OrderStatus.finished:
        case OrderStatus.riderCanceled:
        case OrderStatus.driverCanceled:
        case OrderStatus.artemisUnknown:
          emit(SelectingPoints([], [], true,
              bookingsCount: (state as SelectingPoints).bookingsCount));
          return;

        case OrderStatus.waitingForPostPay:
          emit(OrderInvoice(event.order));
          return;

        case OrderStatus.waitingForReview:
          emit(OrderReview(event.order));
          return;
      }
    }));

    on<DriverLocationUpdatedEvent>((event, emit) {
      if (state is OrderInProgress) {
        emit(OrderInProgress((state as OrderInProgress).currentOrder,
            driverLocation: LatLng(event.location.lat, event.location.lng)));
      }
    });
    on<SetDriversLocations>((event, emit) => emit(SelectingPoints(
        (state as SelectingPoints).points, event.driversLocations, false,
        bookingsCount: (state as SelectingPoints).bookingsCount)));
  }
}

class SelectedPoint {
  String address;
  LatLng point;

  SelectedPoint({required this.point, required this.address});
}

class MarkerData {
  String id;
  LatLng position;
  String assetAddress;
  MarkerType markerType;

  MarkerData(this.id, this.position, this.assetAddress, this.markerType);
}

enum MarkerType { pickup, destination, driver }
