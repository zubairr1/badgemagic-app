import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DrawBadge extends StatefulWidget {
  final String? filename;
  final bool? isSavedCard;
  final bool? isSavedClipart;
  final List<List<int>>? badgeGrid;
  final Map<String, dynamic>? initialData; // Add this for editing

  const DrawBadge({
    super.key,
    this.filename,
    this.isSavedCard = false,
    this.isSavedClipart = false,
    this.badgeGrid,
    this.initialData, // Add this for editing
  });

  @override
  State<DrawBadge> createState() => _DrawBadgeState();
}

class _DrawBadgeState extends State<DrawBadge> {
  var drawToggle = DrawBadgeProvider();
  late SavedBadgeProvider savedBadgeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLandscapeOrientation();
    savedBadgeProvider = Provider.of<SavedBadgeProvider>(context);

    // Load initial data if editing
    if (widget.initialData != null) {
      _loadInitialData(widget.initialData!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Load initial data for editing
  void _loadInitialData(Map<String, dynamic> initialData) {
    final badgeGrid = initialData['messages'][0]['text']
        .map((e) => e.map((e) => e == 1).toList())
        .toList();
    drawToggle.setDrawViewGrid(badgeGrid);
  }

  @override
  Widget build(BuildContext context) {
    FileHelper fileHelper = FileHelper();
    return CommonScaffold(
      index: 1,
      title: 'BadgeMagic',
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        key: const Key(drawBadgeScreen),
        child: Align(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.94,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 100,
                      ),
                      BMBadge(
                        providerInit: (provider) => drawToggle = provider,
                        badgeGrid: widget.badgeGrid
                            ?.map((e) => e.map((e) => e == 1).toList())
                            .toList(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            drawToggle.toggleIsDrawing(true);
                          });
                        },
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit,
                              color: drawToggle.getIsDrawing()
                                  ? colorPrimary
                                  : Colors.black,
                            ),
                            Text(
                              'Draw',
                              style: TextStyle(
                                color: drawToggle.isDrawing
                                    ? colorPrimary
                                    : Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            drawToggle.toggleIsDrawing(false);
                          });
                        },
                        child: Column(
                          children: [
                            Icon(
                              Icons.delete,
                              color: drawToggle.isDrawing
                                  ? Colors.black
                                  : colorPrimary,
                            ),
                            Text(
                              'Erase',
                              style: TextStyle(
                                color: drawToggle.isDrawing
                                    ? Colors.black
                                    : colorPrimary,
                              ),
                            )
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            drawToggle.resetDrawViewGrid();
                          });
                        },
                        child: const Column(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            Text(
                              'Reset',
                              style: TextStyle(color: Colors.black),
                            )
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          List<List<int>> badgeGrid = drawToggle
                              .getDrawViewGrid()
                              .map((e) => e.map((e) => e ? 1 : 0).toList())
                              .toList();
                          List<String> hexString =
                              Converters.convertBitmapToLEDHex(
                                  badgeGrid, false);

                          if (widget.isSavedCard!) {
                            if (widget.filename != null) {
                              // Update existing badge
                              await savedBadgeProvider.editBadgeData(
                                widget.filename!,
                                hexString.join(), // Convert to text
                                widget.initialData?['messages'][0]['flash'] ??
                                    false,
                                widget.initialData?['messages'][0]['marquee'] ??
                                    false,
                                widget.initialData?['messages'][0]['invert'] ??
                                    false,
                                widget.initialData?['messages'][0]['speed'] ??
                                    1,
                                widget.initialData?['messages'][0]['mode'] ??
                                    0,
                              );
                              ToastUtils().showToast("Badge Updated Successfully");
                            } else {
                              // Save new badge
                              await fileHelper.updateBadgeText(
                                widget.filename!,
                                hexString,
                              );
                              ToastUtils().showToast("Badge Saved Successfully");
                            }
                          } else if (widget.isSavedClipart!) {
                            await fileHelper.updateClipart(
                                widget.filename!, badgeGrid);
                            ToastUtils().showToast("Clipart Saved Successfully");
                          } else {
                            await fileHelper.saveImage(drawToggle.getDrawViewGrid());
                            ToastUtils().showToast("Image Saved Successfully");
                          }

                          fileHelper.generateClipartCache();
                        },
                        child: const Column(
                          children: [
                            Icon(
                              Icons.save,
                              color: Colors.black,
                            ),
                            Text('Save', style: TextStyle(color: Colors.black))
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
