class AuthState {
  final bool isLoading;
  final bool hasError;
  final String? partnerId;

  AuthState({required this.isLoading, this.hasError = false, this.partnerId});
}
