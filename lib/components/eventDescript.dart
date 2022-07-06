import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive/hive.dart';
import '../db/db.dart';

class EventDescript extends StatefulWidget {
  EventDescript(
      {Key? key,
      required this.e,
      required this.currLocation,
      required this.placemark,
      required this.user})
      : super(key: key);

  Account user;
  Event e;
  LatLng currLocation;
  Placemark placemark;

  final Box box = Hive.box("events6");
  final Box box2 = Hive.box("accounts10");
  final Box box3 = Hive.box("emails5");

  @override
  State<EventDescript> createState() => _EventDescriptState();
}

class _EventDescriptState extends State<EventDescript> {
  final double latitudeRatio = 68.93; // one degree of latitude to mi
  final double longitudeRatio = 54.58;

  final _formKey = GlobalKey<FormState>();

  String? _title;
  String? _description;
  DateTime? _dateTime;
  TimeOfDay? _time;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    if (newTime != null) {
      setState(() {
        _time = newTime;
      });
    }
  }

  // for rsvp
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)));

    if (picked != null && picked != _dateTime) {
      setState(() {
        _dateTime = picked;
      });
    }
  }

  Widget _showDialog(Event e) {
    return AlertDialog(
      title: Text("Send message to: ${e.userEmail}"),
      content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    filled: true,
                    hintText: "Give a title",
                    labelText: "Title"),
                maxLines: 1,
                onChanged: (String value) {
                  _title = value;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    filled: true,
                    hintText: "Give a description",
                    labelText: "Description"),
                maxLines: 2,
                onChanged: (String value) {
                  _description = value;
                },
              ),
            ],
          )),
      actions: [
        TextButton(
            child: const Text("BACK"),
            onPressed: () => Navigator.pop(context, true)),
        TextButton(
            child: const Text("SUBMIT"),
            onPressed: () {
              Account eAcc = widget.box2.get(e.userEmail);
              Email newEmail = Email(
                  sender: widget.user,
                  reciever: eAcc,
                  title: _title as String,
                  description: _description as String);
              widget.box3.put(DateTime.now().toString(), newEmail);
              Navigator.pop(context, true);
            })
      ],
    );
  }

  Widget _showRSVP(Event e) {
    return AlertDialog(
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
        width: MediaQuery.of(context).size.height * 0.2,
        child: Column(children: [
          ElevatedButton(
              onPressed: (() => _selectDate(context).then),
              child: const Text("Select Date"),
              style:
                  ElevatedButton.styleFrom(primary: const Color(0xff99cae1))),
          ElevatedButton(
              onPressed: (() => _selectTime(context).then),
              child: const Text("Select Time"),
              style:
                  ElevatedButton.styleFrom(primary: const Color(0xff99cae1))),
        ]),
      ),
      actions: [
        TextButton(
            child: const Text("NO"),
            onPressed: () => Navigator.pop(context, true)),
        TextButton(
            child: const Text("YES"),
            onPressed: () {
              if (_dateTime != null && _time != null) {
                Account eAcc = widget.box2.get(e.userEmail);
                DateTime dt = DateTime(_dateTime!.year, _dateTime!.month,
                    _dateTime!.day, _time!.hour, _time!.minute);
                e.rsvpTime = dt;
                e.rsvpee = widget.user;
                Email newEmail = Email(
                    sender: eAcc,
                    reciever: widget.user,
                    title: "${widget.user.name} has RSVPed for ${e.item}",
                    description: "${e.rsvpTime.toString()}");
                widget.box3.put(DateTime.now().toString(), newEmail);
                Navigator.pop(context, true);
                showDialog(
                    context: (context),
                    builder: (BuildContext context) {
                      return _showDialog(e);
                    });
                setState(() {});
              }
            })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightScreen = MediaQuery.of(context).size.height;
    final double widthScreen = MediaQuery.of(context).size.width;
    double diffLat = (widget.currLocation.latitude - widget.e.latitude).abs() *
        latitudeRatio;
    double diffLong =
        (widget.currLocation.longitude - widget.e.longitude).abs() *
            longitudeRatio;
    String dist =
        (sqrt((diffLat * diffLat) + (diffLong * diffLong))).toStringAsFixed(2);
    return Scaffold(
        appBar: AppBar(
            title: Text(
              widget.e.item,
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: Color(0xffb099e1)),
        body: Column(children: [
          SizedBox(
              child: GridView.builder(
                primary: false,
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 10),
                itemCount: widget.e.imgs.length,
                itemBuilder: (context, index) {
                  return Image.memory(base64Decode(widget.e.imgs[index]));
                },
              ),
              height: heightScreen * 0.3,
              width: widthScreen),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
          Expanded(
            child: Row(children: [
              Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(children: [
                        Text(
                          widget.e.item,
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        const Padding(padding: EdgeInsets.all(12)),
                        Text(
                          widget.placemark.street! +
                              ", " +
                              widget.placemark.locality! +
                              ", " +
                              widget.placemark.administrativeArea! +
                              " " +
                              widget.placemark.postalCode!,
                          style: GoogleFonts.lexend(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const Padding(padding: EdgeInsets.all(4)),
                        Text(dist + "mi",
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w200, fontSize: 20)),
                      ]),
                    ),
                  ),
                  flex: 1),
              Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        width: 175,
                        child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  widget.e.latitude,
                                  widget.e.longitude,
                                ),
                                zoom: 14),
                            markers: {
                              Marker(
                                  position: LatLng(
                                      widget.e.latitude, widget.e.longitude),
                                  markerId: MarkerId(
                                      "${widget.e.latitude}${widget.e.longitude}"))
                            },
                            indoorViewEnabled: true,
                            trafficEnabled: true),
                      ),
                    ],
                  ),
                  flex: 1)
            ]),
          ),
          Expanded(
              child: Center(
                  child: Column(
            children: [
              Expanded(
                  child: Text("Description:", style: GoogleFonts.montserrat())),
              Expanded(child: Text(widget.e.description, style: GoogleFonts.montserrat(fontSize: 12), textAlign: TextAlign.center,), flex: 2),
              Expanded(
                child: Text(
                    "Listing ends on ${widget.e.timeEnding.month}/${widget.e.timeEnding.day}/${widget.e.timeEnding.year}",
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w200, fontSize: 12)),
              ),
              Expanded(
                  child: (widget.e.userEmail != widget.user.email)
                      ? (widget.e.rsvpee == null)
                          ? Row(
                              children: [
                                Expanded(
                                    child: Center(
                                      child: Text(
                                        widget.e.userEmail,
                                        style: GoogleFonts.lexend(fontSize: 16),
                                        softWrap: true,
                                      ),
                                    ),
                                    flex: 3),
                                Expanded(
                                  child: TextButton(
                                      child: const Text("Message"),
                                      onPressed: () {
                                        showDialog(
                                            context: (context),
                                            builder: (BuildContext context) {
                                              return _showDialog(widget.e);
                                            });
                                      }),
                                  flex: 1,
                                ),
                                Expanded(
                                  child: TextButton(
                                      child: const Text("RSVP"),
                                      onPressed: () {
                                        showDialog(
                                            context: (context),
                                            builder: (BuildContext context) {
                                              return _showRSVP(widget.e);
                                            });
                                      }),
                                  flex: 1,
                                ),
                              ],
                            )
                          : Text("This event has already been RSVPed!", style: GoogleFonts.montserrat())
                      :  Text("This is your listing!", style: GoogleFonts.montserrat()),
                  flex: 2)
            ],
          ))),
        ]));
  }
}
