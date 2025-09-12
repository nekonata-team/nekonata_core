// Test for nekonata_lint's prefer_context_router rule.
// ignore_for_file: unused_local_variable, unused_element

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class _UseAutoRouteWidget extends StatelessWidget {
  const _UseAutoRouteWidget();

  @override
  Widget build(BuildContext context) {
    // expect_lint: prefer_context_router
    final router1 = AutoRouter.of(context);
    final router2 = context.router;
    return Container();
  }
}
