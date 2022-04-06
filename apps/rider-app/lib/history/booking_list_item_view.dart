import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:ridy/generated/l10n.dart';
import '../config.dart';
import '../graphql/generated/graphql_api.dart';
import 'package:intl/intl.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:dotted_line/dotted_line.dart';

class BookingListItemView extends StatelessWidget {
  final HistoryOrderItemMixin$OrderEdge$Order order;
  final Function() canceled;
  const BookingListItemView(this.order, this.canceled, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      children: [
        Row(
          children: [
            Image.network(
              serverUrl + order.service.media.address,
              width: 100,
              height: 50,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.service.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16))
                    .pOnly(bottom: 4),
                Text(DateFormat('yyyy-MM-dd | kk:mm').format(order.createdOn),
                    style: Theme.of(context).textTheme.overline)
              ],
            ).pOnly(left: 8),
            const Spacer(),
            Mutation(
                options:
                    MutationOptions(document: CANCEL_BOOKING_MUTATION_DOCUMENT),
                builder: (RunMutation runMutation, QueryResult? result) {
                  return IconButton(
                    onPressed: () {
                      runMutation(CancelBookingArguments(id: order.id).toJson())
                          .networkResult;
                      canceled();
                    },
                    icon: Icon(Icons.cancel),
                    color: Colors.deepOrange,
                  );
                })
          ],
        ).pOnly(bottom: 12),
        ...order.addresses.mapIndexed((e, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    child: Icon(
                      getIconByIndex(index, order.addresses.length),
                      size: 20,
                      color: Colors.white,
                    ),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.black),
                  ),
                  Expanded(
                    child:
                        Text(e, overflow: TextOverflow.ellipsis).pOnly(left: 4),
                  )
                ],
              ).p4(),
              if (index < order.addresses.length - 1)
                const DottedLine(
                        direction: Axis.vertical,
                        lineLength: 15,
                        lineThickness: 5.0,
                        dashLength: 4.0,
                        dashColor: Colors.black)
                    .pOnly(left: 14)
            ],
          );
        }).toList(),
      ],
    ).p8());
  }

  IconData getIconByIndex(int index, int length) {
    if (index == 0) {
      return Icons.keyboard_arrow_down;
    } else if (index == length - 1) {
      return Icons.keyboard_arrow_up;
    } else {}
    return Icons.more_vert;
  }
}
