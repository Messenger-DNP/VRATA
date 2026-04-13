import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:frontend/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/login_use_case.dart';
import 'package:frontend/features/auth/domain/usecases/register_use_case.dart';

final mockAuthDatasourceProvider = Provider<MockAuthDatasource>(
  (ref) => MockAuthDatasource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(mockAuthDatasourceProvider)),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);
