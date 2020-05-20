// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:better_som_today/constants.dart';
import 'package:better_som_today/data/bettersom_options.dart';
import 'package:better_som_today/app.dart';

class Backdrop extends StatefulWidget {
  const Backdrop({
    this.settingsPage,
    this.homePage,
  });

  final Widget settingsPage;
  final Widget homePage;

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin, FlareController {
  AnimationController _settingsPanelController;
  FocusNode _settingsPageFocusNode;
  ValueNotifier<bool> _isSettingsOpenNotifier;
  Widget _homePage;

  FlutterActorArtboard _artboard;
  FlareAnimationLayer _animationLayer;

  @override
  void initState() {
    super.initState();
    _settingsPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _settingsPageFocusNode = FocusNode();
    _isSettingsOpenNotifier = ValueNotifier(false);
    _homePage = SomApp();
  }

  @override
  void dispose() {
    _settingsPanelController.dispose();
    _settingsPageFocusNode.dispose();
    _isSettingsOpenNotifier.dispose();
    super.dispose();
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _artboard = artboard;
    initAnimationLayer();
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    // This is a necessary override for the [FlareController] mixin.
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (_animationLayer != null) {
      final layer = _animationLayer;
      layer.time = _settingsPanelController.value * layer.duration;
      layer.animation.apply(layer.time, _artboard, 1);
      if (layer.isDone || layer.time == 0) {
        _animationLayer = null;
      }
    }
    return _animationLayer != null;
  }

  void initAnimationLayer() {
    if (_artboard != null) {
      final animationName = 'Animations';
      final animation = _artboard.getAnimation(animationName);
      _animationLayer = FlareAnimationLayer()
        ..name = animationName
        ..animation = animation;
    }
  }

  void _toggleSettings() {
    initAnimationLayer();
    // Animate the settings panel to open or close.
    _settingsPanelController.fling(
        velocity: _isSettingsOpenNotifier.value ? -1 : 1);
    _isSettingsOpenNotifier.value = !_isSettingsOpenNotifier.value;
    isActive.value = true;
  }

  Animation<RelativeRect> _slideDownSettingsPageAnimation(
      BoxConstraints constraints) {
    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(0, -constraints.maxHeight, 0, 0),
      end: const RelativeRect.fromLTRB(0, 0, 0, 0),
    ).animate(
      CurvedAnimation(
        parent: _settingsPanelController,
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.ease,
        ),
      ),
    );
  }

  Animation<RelativeRect> _slideDownHomePageAnimation(
      BoxConstraints constraints) {
    return RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 0, 0, 0),
      end: RelativeRect.fromLTRB(
        0,
        constraints.biggest.height - galleryHeaderHeight,
        0,
        -galleryHeaderHeight,
      ),
    ).animate(
      CurvedAnimation(
        parent: _settingsPanelController,
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.ease,
        ),
      ),
    );
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final isDesktop = false;

    final Widget settingsPage = ValueListenableBuilder<bool>(
      valueListenable: _isSettingsOpenNotifier,
      builder: (context, isSettingsOpen, child) {
        return ExcludeSemantics(
          excluding: !isSettingsOpen,
        );
      },
    );

    final Widget homePage = ValueListenableBuilder<bool>(
      valueListenable: _isSettingsOpenNotifier,
      builder: (context, isSettingsOpen, child) {
        return ExcludeSemantics(
          excluding: isSettingsOpen,
          child: FocusTraversalGroup(child: _homePage),
        );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SomOptions.of(context).resolvedSystemUiOverlayStyle(),
      child: Stack(
        children: [
          if (!isDesktop) ...[
            // Slides the settings page up and down from the top of the
            // screen.
            PositionedTransition(
              rect: _slideDownSettingsPageAnimation(constraints),
              child: settingsPage,
            ),
            // Slides the home page up and down below the bottom of the
            // screen.
            PositionedTransition(
              rect: _slideDownHomePageAnimation(constraints),
              child: homePage,
            ),
          ],
          if (isDesktop) ...[
            Semantics(sortKey: const OrdinalSortKey(2), child: homePage),
            ValueListenableBuilder<bool>(
              valueListenable: _isSettingsOpenNotifier,
              builder: (context, isSettingsOpen, child) {
                if (isSettingsOpen) {
                  return ExcludeSemantics(
                    child: Listener(
                      onPointerDown: (_) => _toggleSettings(),
                      child: const ModalBarrier(dismissible: false),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
            Semantics(
              sortKey: const OrdinalSortKey(3),
              child: ScaleTransition(
                alignment: Directionality.of(context) == TextDirection.ltr
                    ? Alignment.topRight
                    : Alignment.topLeft,
                scale: CurvedAnimation(
                  parent: _settingsPanelController,
                  curve: Curves.easeIn,
                  reverseCurve: Curves.easeOut,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Material(
                    elevation: 7,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(40),
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 560,
                        maxWidth: desktopSettingsWidth,
                        minWidth: desktopSettingsWidth,
                      ),
                      child: settingsPage,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: _buildStack,
    );
  }
}
