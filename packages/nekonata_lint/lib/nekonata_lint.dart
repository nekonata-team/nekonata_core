import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// This is the entrypoint of our custom linter
PluginBase createPlugin() => _NekonataLinter();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _NekonataLinter extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const AutoRouteLint(),
  ];

  @override
  List<Assist> getAssists() => [AutoRouteAssist()];
}

class AutoRouteLint extends DartLintRule {
  const AutoRouteLint() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_context_router',
    problemMessage: 'Use `context.router` instead of `AutoRouter.of(context)`.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'of' &&
          node.target != null &&
          node.target.toString() == 'AutoRouter' &&
          node.argumentList.arguments.length == 1 &&
          node.argumentList.arguments.first.toString() == 'context') {
        reporter.atNode(node, code);
      }
    });
  }
}

class AutoRouteAssist extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!target.intersects(node.sourceRange)) return;

      if (node.methodName.name == 'of' &&
          node.target != null &&
          node.target.toString() == 'AutoRouter' &&
          node.argumentList.arguments.length == 1 &&
          node.argumentList.arguments.first.toString() == 'context') {
        reporter
            .createChangeBuilder(
              message: 'Convert to context.router',
              priority: 30,
            )
            .addDartFileEdit((builder) {
              builder.addSimpleReplacement(node.sourceRange, 'context.router');
            });
      }
    });
  }
}
