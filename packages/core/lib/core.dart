/// Framework-agnostic primitives shared by every app in the workspace.
///
/// This package intentionally has no Flutter dependency so it can be reused by
/// command-line tools, isolates, and tests.
library;

export 'src/extensions/datetime_extensions.dart';
export 'src/extensions/iterable_extensions.dart';
export 'src/extensions/string_extensions.dart';
export 'src/logger.dart';
export 'src/math/math.dart';
export 'src/result.dart';
export 'src/typedefs.dart';
