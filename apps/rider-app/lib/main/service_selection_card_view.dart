import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:ridy/generated/l10n.dart';
import '../graphql/generated/graphql_api.dart';
import 'bloc/main_bloc.dart';
import '../main/select_service_view.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ServiceSelectionCardView extends StatelessWidget {
  const ServiceSelectionCardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainBloc = context.read<MainBloc>();
    return BlocBuilder<MainBloc, MainBlocState>(builder: (context, state) {
      return Query(
          options: QueryOptions(
              document: GET_FARE_QUERY_DOCUMENT,
              variables: GetFareArguments(
                      points: (state as OrderPreview)
                          .points
                          .map((e) => PointInput(
                              lat: e.point.latitude, lng: e.point.longitude))
                          .toList(),
                      twoWay: state.twoWay)
                  .toJson()),
          builder: (QueryResult result,
              {Future<QueryResult?> Function()? refetch,
              FetchMore? fetchMore}) {
            if (result.isLoading) {
              return Card(child: const CupertinoActivityIndicator().p16());
            }
            if (result.hasException) {
              return Center(
                child: Text(result.exception!.graphqlErrors
                    .map((e) => e.message)
                    .join(',')),
              );
            }
            final fareResult = GetFare$Query.fromJson(result.data!).getFare;
            return Mutation(
              options:
                  MutationOptions(document: CREATE_ORDER_MUTATION_DOCUMENT),
              builder: (RunMutation runMutation, QueryResult? result) {
                return Column(
                  children: [
                    Row(
                      children: [
                        if (state.twoWay)
                          FloatingActionButton.extended(
                            onPressed: () => mainBloc.add(ShowPreview(
                                points: state.points, twoWay: false)),
                            label: const Text("One Way"),
                            icon: const Icon(Icons.arrow_right_alt),
                          ),
                        if (!state.twoWay)
                          FloatingActionButton.extended(
                            onPressed: () => mainBloc.add(ShowPreview(
                                points: state.points, twoWay: true)),
                            label: const Text("Two Way"),
                            icon: const Icon(Icons.replay),
                          ),
                        const Spacer(),
                        FloatingActionButton.extended(
                                heroTag: 'cancelFab',
                                onPressed: () => mainBloc.add(ResetState()),
                                label: Text(S.of(context).action_cancel),
                                icon: const Icon(Icons.close))
                            .pOnly(bottom: 8)
                            .objectCenterRight(),
                      ],
                    ),
                    SelectServiceView(
                      data: fareResult,
                      onServiceSelect:
                          (String serviceId, int intervalMinutes) async {
                        final fcmId = await getFcmId(context);
                        final now = DateTime.now();
                        final args = CreateOrderArguments(
                                input: CreateOrderInput(
                                    serviceId:
                                        int.parse(state.selectedService!),
                                    intervalMinutes: state.selectedTime != null
                                        ? DateTime(
                                                now.year,
                                                now.month,
                                                now.day,
                                                state.selectedTime!.hour,
                                                state.selectedTime!.minute)
                                            .difference(now)
                                            .inMinutes
                                        : 0,
                                    points: state.points
                                        .map((e) => PointInput(
                                            lat: e.point.latitude,
                                            lng: e.point.longitude))
                                        .toList(),
                                    addresses: state.points
                                        .map((e) => e.address)
                                        .toList()),
                                notificationPlayerId: fcmId ?? "")
                            .toJson();
                        final result = await runMutation(args).networkResult;
                        final _order =
                            CreateOrder$Mutation.fromJson(result!.data!)
                                .createOrder;
                        if (_order.status == OrderStatus.booked) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text("Booked!"),
                                    content: Text(
                                        "Order has been successfully booked. You can track this order status from Trip history menu."),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          mainBloc.add(ResetState());
                                        },
                                        child: Text(S.of(context).action_ok),
                                      )
                                    ],
                                  ));
                        } else {
                          mainBloc.add(CurrentOrderUpdated(_order));
                        }
                      },
                    ),
                  ],
                );
              },
            );
          });
    });
  }

  Future<String?> getFcmId(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title:
                    Text(S.of(context).message_notification_permission_title),
                content: Text(S
                    .of(context)
                    .message_notification_permission_denined_message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(S.of(context).action_ok),
                  )
                ],
              ));
      return null;
    } else {
      return messaging.getToken(
        vapidKey:
            "BG0pQznji1XrJWPiTe0BSDdLGAeVJEqqwezYkwv5m2CMeJR7_MkPb2j0GdruYLHEGgxJ-PKA1DgDhQJc5XagUmQ",
      );
    }
  }
}
