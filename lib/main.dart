import 'app/bootstrap.dart';
import 'app/config/env_config.dart';

/// Default entrypoint, used by `flutter run` and `flutter build web`, which do
/// not take a flavor. It resolves to the development config so those commands
/// keep working; a shipped build always goes through one of the explicit
/// `main_<flavor>.dart` entrypoints.
void main() => bootstrap(EnvConfig.development);
