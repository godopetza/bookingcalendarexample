import 'package:booking_calendar/booking_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'auth.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final int _currentHours = 2;
  int totalAmount = 100;
  final now = DateTime.now();
  late BookingService myBookingService;

  final String uid = AuthService().currentUser!.uid;

  // final bookings = FirebaseFirestore.instance.collection('bookings');

  CollectionReference bookings =
      FirebaseFirestore.instance.collection('bookings');

  ///How you actually get the stream of data from Firestore with the help of the previous function
  ///note that this query filters are for my data structure, you need to adjust it to your solution.
  Stream<dynamic>? getBookingStreamFirebase(
      {required DateTime end, required DateTime start}) {
    CollectionReference<SportBooking> getBookingStream(
        {required String placeId}) {
      return bookings
          .doc(placeId)
          .collection('bookings')
          .withConverter<SportBooking>(
            fromFirestore: (snapshots, _) =>
                SportBooking.fromJson(snapshots.data()!),
            toFirestore: (snapshots, _) => snapshots.toJson(),
          );
    }

    return getBookingStream(placeId: 'placeId')
        .where('bookingStart', isGreaterThanOrEqualTo: start)
        .where('bookingStart', isLessThanOrEqualTo: end)
        .snapshots();
  }

  ///After you fetched the data from firestore, we only need to have a list of datetimes from the bookings:
  List<DateTimeRange> convertStreamResultFirebase(
      {required dynamic streamResult}) {
    ///this snapshot should be converted to List<DateTimeRange>
    // final data = snapshot.requireData; **//THIS IS THE MOST IMPORTANT LINE**

    ///here you can parse the streamresult and convert to [List<DateTimeRange>]
    ///Note that this is dynamic, so you need to know what properties are available on your result, in our case the [SportBooking] has bookingStart and bookingEnd property
    List<DateTimeRange> converted = [];
    
    //Here's the problem. StreamResult causes stack overflow on the widget
    for (var i = 0; i < streamResult.size; i++) {
      final item = streamResult.docs[i].data();
//       print('1');
//       print(item.toJson());
      converted.add(
          DateTimeRange(start: (item.bookingStart!), end: (item.bookingEnd!)));
    }
        
    return converted;
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting;
    //limit slots
    myBookingService = BookingService(
        serviceName: 'widget.facilityname',
        serviceDuration: 60,
        bookingEnd: DateTime(now.year, now.month, now.day, 20, 0),
        bookingStart: DateTime(now.year, now.month, now.day, 8, 0));
  }

  Future<dynamic> uploadBookingMock(
      {required BookingService newBooking}) async {
    final uploadedBooking = SportBooking(
      email: 'email',
      phoneNumber: 'phoneNumber',
      placeAddress: 'placeAddress',
      bookingStart: newBooking.bookingStart,
      placeId: 'placeId',
      userId: 'userId',
      userName: 'userName',
      serviceName: 'serviceName',
      serviceDuration: _currentHours * 60,
      servicePrice: 500,
    );

    await Future.delayed(const Duration(seconds: 1));
    await bookings
        .doc('placeId')
        .collection('bookings')
        .add(uploadedBooking.toJson())
        .catchError((error) => print("failed booking: $error"));
    print('${uploadedBooking.toJson()} has been uploaded');
  }

  Widget _bookingexplaination() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: Icon(
                Icons.circle,
                color: Colors.green[200],
              ),
              label: const Text('Available',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {},
            ),
            TextButton.icon(
              icon: Icon(
                Icons.circle,
                color: Colors.orange.shade300,
              ),
              label: const Text('Start Time',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {},
            ),
            TextButton.icon(
              icon: const Icon(
                Icons.circle,
                color: Colors.red,
              ),
              label: const Text('Unavailable',
                  style: TextStyle(color: Colors.black)),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  List<DateTimeRange> converted = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BookingCalendar(
            bookingService: myBookingService,
            getBookingStream: getBookingStreamFirebase,
            uploadBooking: uploadBookingMock,
            convertStreamResultToDateTimeRanges: convertStreamResultFirebase,
            bookingExplanation: _bookingexplaination(),
        ),
      ),
    );
  }
}

class AppUtil {
  static DateTime timeStampToDateTime(Timestamp timestamp) {
    return DateTime.parse(timestamp.toDate().toString());
  }

  static Timestamp dateTimeToTimeStamp(DateTime? dateTime) {
    return Timestamp.fromDate(dateTime ?? DateTime.now()); //To TimeStamp
  }
}

@JsonSerializable(explicitToJson: true)
class SportBooking {
  /// The generated code assumes these values exist in JSON.
  final String? userId;
  final String? userName;
  final String? placeId;
  final String? serviceName;
  final int? serviceDuration;
  final int? servicePrice;

  //Because we are storing timestamp in Firestore, we need a converter for DateTime
  /* static DateTime timeStampToDateTime(Timestamp timestamp) {
    return DateTime.parse(timestamp.toDate().toString());
  }

  static Timestamp dateTimeToTimeStamp(DateTime? dateTime) {
    return Timestamp.fromDate(dateTime ?? DateTime.now()); //To TimeStamp
  }*/
  @JsonKey(
      fromJson: AppUtil.timeStampToDateTime,
      toJson: AppUtil.dateTimeToTimeStamp)
  final DateTime? bookingStart;
  @JsonKey(
      fromJson: AppUtil.timeStampToDateTime,
      toJson: AppUtil.dateTimeToTimeStamp)
  final DateTime? bookingEnd;
  final String? email;
  final String? phoneNumber;
  final String? placeAddress;

  SportBooking(
      {this.email,
      this.phoneNumber,
      this.placeAddress,
      this.bookingStart,
      this.bookingEnd,
      this.placeId,
      this.userId,
      this.userName,
      this.serviceName,
      this.serviceDuration,
      this.servicePrice});

  /// Connect the generated [_$SportBookingFromJson] function to the `fromJson`
  /// factory.
  factory SportBooking.fromJson(Map<String, dynamic> json) =>
      SportBooking.fromJson(json);

  get minutes => serviceDuration;

  /// Connect the generated [_$SportBookingToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => {
        'email': email,
        'phoneNumber': phoneNumber,
        'placeAddress': placeAddress,
        'bookingStart': bookingStart,
        'bookingEnd': bookingStart!.add(Duration(minutes: minutes)),
        'placeId': placeId,
        'userId': userId,
        'userName': userName,
        'serviceName': serviceName,
        'serviceDuration': serviceDuration,
        'servicePrice': servicePrice,
      };
}
