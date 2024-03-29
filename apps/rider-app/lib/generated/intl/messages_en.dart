// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(hour, minute) => "Book for ${hour}:${minute}";

  static String m1(count) => "& ${count} other currencies";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "action_apply": MessageLookupByLibrary.simpleMessage("Apply"),
        "action_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "action_delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "action_next": MessageLookupByLibrary.simpleMessage("Next"),
        "action_ok": MessageLookupByLibrary.simpleMessage("OK"),
        "action_save": MessageLookupByLibrary.simpleMessage("Save"),
        "addresses_empty_state_message":
            MessageLookupByLibrary.simpleMessage("Noting To See Here."),
        "announcements_empty_state_message":
            MessageLookupByLibrary.simpleMessage("Nothing to see here."),
        "app_name": MessageLookupByLibrary.simpleMessage("Ridy"),
        "copyright_notice": MessageLookupByLibrary.simpleMessage(
            "Copyright © ridy.io, All rights reserved."),
        "coupon_heading": MessageLookupByLibrary.simpleMessage(
            "Enter the coupon code below:"),
        "coupon_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Coupon code"),
        "create_address_details_empty_error":
            MessageLookupByLibrary.simpleMessage(
                "Please enter details about the address"),
        "create_address_details_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Details"),
        "create_address_name_empty_error": MessageLookupByLibrary.simpleMessage(
            "Please enter name of location"),
        "create_address_title_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Title"),
        "driver_info_card_call": MessageLookupByLibrary.simpleMessage("Call"),
        "driver_info_card_message":
            MessageLookupByLibrary.simpleMessage("Message"),
        "enum_address_type_home": MessageLookupByLibrary.simpleMessage("Home"),
        "enum_address_type_other":
            MessageLookupByLibrary.simpleMessage("Other"),
        "enum_address_type_partner":
            MessageLookupByLibrary.simpleMessage("Partner"),
        "enum_address_type_work": MessageLookupByLibrary.simpleMessage("Work"),
        "enum_gender_female": MessageLookupByLibrary.simpleMessage("Female"),
        "enum_gender_male": MessageLookupByLibrary.simpleMessage("Male"),
        "enum_gender_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "enum_rider_transaction_deduct_correction":
            MessageLookupByLibrary.simpleMessage("Correction"),
        "enum_rider_transaction_deduct_order_fee":
            MessageLookupByLibrary.simpleMessage("Order Free"),
        "enum_rider_transaction_deduct_withdraw":
            MessageLookupByLibrary.simpleMessage("Withdraw"),
        "enum_rider_transaction_recharge_bank_transfer":
            MessageLookupByLibrary.simpleMessage("Bank Transfer"),
        "enum_rider_transaction_recharge_correction":
            MessageLookupByLibrary.simpleMessage("Correction"),
        "enum_rider_transaction_recharge_gift":
            MessageLookupByLibrary.simpleMessage("Gift"),
        "enum_rider_transaction_recharge_in_app_payment":
            MessageLookupByLibrary.simpleMessage("In-app Payment"),
        "enum_unknown": MessageLookupByLibrary.simpleMessage("Unkonwn"),
        "history_payment_method_cash":
            MessageLookupByLibrary.simpleMessage("Cash"),
        "invoice_apply_coupon_action":
            MessageLookupByLibrary.simpleMessage("Apply Coupon"),
        "invoice_coupon_discount":
            MessageLookupByLibrary.simpleMessage("Coupon discount"),
        "invoice_pay_online_action":
            MessageLookupByLibrary.simpleMessage("Pay Online"),
        "invoice_service_fee":
            MessageLookupByLibrary.simpleMessage("Service Fee"),
        "invoice_subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading"),
        "login_cell_number_empty_error": MessageLookupByLibrary.simpleMessage(
            "Please enter the phone number in correct format"),
        "login_cell_number_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Cell Number"),
        "login_heading_first_line":
            MessageLookupByLibrary.simpleMessage("Enter your"),
        "login_heading_second_line":
            MessageLookupByLibrary.simpleMessage("mobile number"),
        "login_heading_third_line": MessageLookupByLibrary.simpleMessage(
            "We will send you confirmation code"),
        "looking_cancel_request":
            MessageLookupByLibrary.simpleMessage("Cancel Request"),
        "looking_heading": MessageLookupByLibrary.simpleMessage(
            "Looking for ride, please wait..."),
        "menu_about": MessageLookupByLibrary.simpleMessage("About"),
        "menu_announcements":
            MessageLookupByLibrary.simpleMessage("Announcements"),
        "menu_chat": MessageLookupByLibrary.simpleMessage("Chat"),
        "menu_login": MessageLookupByLibrary.simpleMessage("Login"),
        "menu_logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "menu_profile": MessageLookupByLibrary.simpleMessage("Profile"),
        "menu_saved_locations":
            MessageLookupByLibrary.simpleMessage("Saved Locations"),
        "menu_trip_history":
            MessageLookupByLibrary.simpleMessage("Trip History"),
        "menu_wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
        "message_notification_permission_denined_message":
            MessageLookupByLibrary.simpleMessage(
                "Notification permission was denied previously. In order to get new order\\\'s notifications you can enable the permission from app settings."),
        "message_notification_permission_title":
            MessageLookupByLibrary.simpleMessage("Notification Permission"),
        "place_search_hint": MessageLookupByLibrary.simpleMessage(
            "Enter keywords of the location"),
        "point_selection_add_destination":
            MessageLookupByLibrary.simpleMessage("Add Destination"),
        "point_selection_confirm_pickup":
            MessageLookupByLibrary.simpleMessage("Confirm Pickup Location"),
        "point_selection_final_destination":
            MessageLookupByLibrary.simpleMessage("Final Destination"),
        "profile_email": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "profile_firstname": MessageLookupByLibrary.simpleMessage("First Name"),
        "profile_gender": MessageLookupByLibrary.simpleMessage("Gender"),
        "profile_lastname": MessageLookupByLibrary.simpleMessage("Last Name"),
        "profile_mobilenumber":
            MessageLookupByLibrary.simpleMessage("Mobile Number"),
        "review_action_submit_review":
            MessageLookupByLibrary.simpleMessage("Submit Review"),
        "review_text_heading": MessageLookupByLibrary.simpleMessage(
            "How would you rate your experience?"),
        "review_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Add Comment"),
        "service_selection_book_later": m0,
        "service_selection_book_now":
            MessageLookupByLibrary.simpleMessage("Book Now"),
        "top_up_sheet_pay_button": MessageLookupByLibrary.simpleMessage("Pay"),
        "top_up_sheet_textfield_hint":
            MessageLookupByLibrary.simpleMessage("Input amount to recharge"),
        "trip_history_canceled_tab":
            MessageLookupByLibrary.simpleMessage("Canceled"),
        "trip_history_completed_tab":
            MessageLookupByLibrary.simpleMessage("Completed"),
        "trip_history_empty_state_message":
            MessageLookupByLibrary.simpleMessage(
                "No past order has been recorded."),
        "verify_phone_code_empty_message": MessageLookupByLibrary.simpleMessage(
            "Verification code is not entered."),
        "verify_phone_heading_first_line":
            MessageLookupByLibrary.simpleMessage("Enter code sent"),
        "verify_phone_heading_second_line":
            MessageLookupByLibrary.simpleMessage("to your phone"),
        "verify_phone_heading_third_line": MessageLookupByLibrary.simpleMessage(
            "We will send you the confirmation code"),
        "wallet_activities_heading":
            MessageLookupByLibrary.simpleMessage("Activities"),
        "wallet_add_credit": MessageLookupByLibrary.simpleMessage("Add Credit"),
        "wallet_empty_state_message":
            MessageLookupByLibrary.simpleMessage("No history recorded."),
        "wallet_gateway_empty_state":
            MessageLookupByLibrary.simpleMessage("No Gateway is available."),
        "wallet_other_currencies_available": m1,
        "wallet_select_currency":
            MessageLookupByLibrary.simpleMessage("Select currency:"),
        "wallet_select_payment_method":
            MessageLookupByLibrary.simpleMessage("Select Payment Method:"),
        "wallet_switch_currency": MessageLookupByLibrary.simpleMessage("Switch")
      };
}
