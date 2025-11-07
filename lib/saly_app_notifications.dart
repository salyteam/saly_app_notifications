import 'package:flutter/material.dart';
import 'package:saly_ui_kit/saly_ui_kit.dart';

///Defines notification appearance
enum NotificationType { ok, error, info }

///Class Notification is using for configurate notification,
///Positions, type, showing time and something that
class Notification {
  Notification({
    required this.title,
    this.subtitle,
    this.curve,
    this.offset,
    this.insetPadding,
    this.width,
    this.duration = const Duration(seconds: 10),
    this.dismissed = false,
    this.axis = Axis.vertical,
    this.alignment = Alignment.topCenter,
    this.type = NotificationType.ok,
  });

  final String title;
  final String? subtitle;
  final NotificationType type;
  final Duration duration;
  final bool dismissed;
  final Axis axis;
  final Alignment alignment;
  final Offset? offset;
  final Curve? curve;
  final double? width;
  final EdgeInsets? insetPadding;
}

///Widget for inject in widget tree in your app
///or scope
class NotificationManager extends StatefulWidget {
  const NotificationManager({required this.child, super.key});

  static NotificationManagerState of(BuildContext context) => _NotificationServiceScope.of(context);

  static NotificationManagerState? maybeOf(BuildContext context) => _NotificationServiceScope.maybeOf(context);

  final Widget child;

  @override
  State<NotificationManager> createState() => NotificationManagerState();
}

///The NotificationManagerState main component which contain all login
///for showing, position, and scheduling
class NotificationManagerState extends State<NotificationManager> with TickerProviderStateMixin {
  final _layerLink = LayerLink();

  void showNotification(Notification notification) => _showNotification(notification);

  void _showNotification(Notification notification) {
    OverlayEntry? overlayEntry;

    void onRemove() {
      overlayEntry?.remove();
      overlayEntry?.dispose();
      setState(() => overlayEntry = null);
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        width: notification.width ?? 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: notification.offset ?? const Offset(0, 8),
          targetAnchor: notification.alignment,
          followerAnchor: notification.alignment,
          child: SafeArea(
            child: _NotificationWidget(notification: notification, onRemove: onRemove),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: _NotificationServiceScope(notificationState: this, child: widget.child),
  );
}

///Inherited widget for rapid searching in the hierarchy of widgets
class _NotificationServiceScope extends InheritedWidget {
  const _NotificationServiceScope({required super.child, required this.notificationState});

  static NotificationManagerState of(BuildContext context) {
    final NotificationManagerState? result = maybeOf(context);
    assert(result != null, 'No NotificationServiceScope found in context');
    return result!;
  }

  static NotificationManagerState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_NotificationServiceScope>()?.notificationState;
  }

  final NotificationManagerState notificationState;

  @override
  bool updateShouldNotify(_NotificationServiceScope old) => false;
}

final class _NotificationWidget extends StatefulWidget {
  const _NotificationWidget({required this.notification, this.onRemove});

  final Notification notification;
  final void Function()? onRemove;

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget> with TickerProviderStateMixin {
  late final Notification _notification = widget.notification;
  AnimationController? _animationController, _sizeAnimationController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _sizeAnimationController = AnimationController(vsync: this, duration: _notification.duration);
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    final delta = switch (_notification.alignment) {
      Alignment.bottomLeft || Alignment.topLeft || Alignment.topCenter => -1.0,
      _ => 1.0,
    };
    final startPoint = 2 * delta;
    final beginOffset = _notification.axis == Axis.vertical ? Offset(0, startPoint) : Offset(startPoint, 0);

    _slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: _notification.curve ?? Curves.bounceOut,
        reverseCurve: Curves.easeOut,
      ),
    );
    _sizeAnimation = Tween<double>(begin: 1, end: 0).animate(_sizeAnimationController!);

    _animationController?.forward();
    _sizeAnimationController?.forward();

    _sizeAnimationController?.addListener(() {
      if (_sizeAnimationController?.status == AnimationStatus.completed) {
        _remove();
      }
    });
  }

  Future<void> _remove() async {
    await _animationController?.reverse();
    widget.onRemove?.call();
  }

  DismissDirection _direction() {
    if (_notification.axis == Axis.vertical) {
      return switch (_notification.alignment) {
        Alignment.topCenter || Alignment.topRight || Alignment.topLeft => DismissDirection.up,
        Alignment.bottomCenter || Alignment.bottomRight || Alignment.bottomLeft => DismissDirection.down,
        _ => DismissDirection.up,
      };
    } else {
      return switch (_notification.alignment) {
        Alignment.bottomCenter => DismissDirection.down,
        Alignment.bottomRight || Alignment.topRight => DismissDirection.startToEnd,
        Alignment.bottomLeft || Alignment.topLeft => DismissDirection.endToStart,
        Alignment.topCenter => DismissDirection.up,
        _ => DismissDirection.up,
      };
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.all(0).copyWith(
        left: _notification.insetPadding?.left,
        right: _notification.insetPadding?.right,
        top: _notification.insetPadding?.top,
        bottom: _notification.insetPadding?.bottom,
      ),
      child: SlideTransition(
        position: _slideAnimation!,
        child: Dismissible(
          key: UniqueKey(),

          onDismissed: (_) {
            widget.onRemove?.call();
          },
          direction: _direction(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.neutralPrimaryS2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(strokeAlign: BorderSide.strokeAlignOutside, color: context.colors.neutralSecondaryS3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: _sizeAnimation!,
                      child: SizedBox.expand(child: ColoredBox(color: context.colors.neutralPrimaryS1)),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        spacing: 12,
                        children: [
                          _NotificationTypeMarker(_notification.type),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                Text(_notification.title, style: context.fonts.body),
                                if (_notification.subtitle != null)
                                  Text(_notification.subtitle!, style: context.fonts.small),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: _remove,
                              child: SalyAssets.icons.cross.svg(
                                colorFilter: ColorFilter.mode(context.colors.neutralSecondaryS4, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _sizeAnimationController?.dispose();
    _animationController?.dispose();
    _sizeAnimation = null;
    _slideAnimation = null;
    super.dispose();
  }
}

final class _NotificationTypeMarker extends StatelessWidget {
  const _NotificationTypeMarker(this._type);

  final NotificationType _type;

  Color _backgroundColor(BuildContext context) => switch (_type) {
    NotificationType.ok => context.colors.statusOkS1,
    NotificationType.info => context.colors.statusInfoS1,
    NotificationType.error => context.colors.statusErrorS1,
  };

  SvgGenImage _icon() => switch (_type) {
    NotificationType.ok => SalyAssets.icons.statusOk,
    _ => SalyAssets.icons.error,
  };

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 32,
    child: _icon().svg(colorFilter: ColorFilter.mode(_backgroundColor(context), BlendMode.srcIn)),
  );
}
