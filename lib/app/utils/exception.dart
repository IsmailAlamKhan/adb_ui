class AppException implements Exception {
  String message;
  String? code;

  AppException(Object? e, [String? code]) : message = e.toString();

  @override
  String toString() => message;
}

// class AppDioException extends AppException {
//   final bool isCanceledByUser;
//   final DioError dioError;

//   AppDioException(this.dioError)
//       : isCanceledByUser = getIsCanceledByUser(dioError),
//         super(null) {
//     final _dioError = fromDioError(dioError);
//     message = _dioError.toString();
//   }
//   static const canceledByUser = 'Reason CanceledByUser';
//   static bool getIsCanceledByUser(DioError dioError) {
//     if (dioError.type == DioErrorType.cancel) {
//       return dioError.error.toString().contains(canceledByUser);
//     }
//     return false;
//   }

//   static Object fromDioError(DioError dioError) {
//     switch (dioError.type) {
//       case DioErrorType.cancel:
//         return "Request to API server was cancelled";
//       case DioErrorType.connectTimeout:
//         return "Connection timeout with API server";
//       case DioErrorType.other:
//         return "Connection to API server failed due to internet connection or server down";
//       case DioErrorType.receiveTimeout:
//         return "Receive timeout in connection with API server";
//       case DioErrorType.response:
//         if (dioError.response == null) {
//           return dioError.message;
//         } else {
//           return _handleError(dioError.response!);
//         }
//       case DioErrorType.sendTimeout:
//         return "Send timeout in connection with API server";
//       default:
//         return "Unknown error";
//     }
//   }

//   static Object _handleError(Response res) {
//     final data = res.data;
//     if (data != null) {
//       if (data is Map) {
//         if (data.containsKey('message')) {
//           return data['message'];
//         }
//       }
//     }
//     final statusCode = res.statusCode;
//     switch (statusCode) {
//       case 301:
//         return "Moved Permanently";
//       case 400:
//         return 'Bad request';
//       case 404:
//         return 'Not found';
//       case 500:
//         return 'Internal server error';
//       default:
//         return 'Something went wrong';
//     }
//   }
// }

class SwallowedError extends AppException {
  SwallowedError(Object super.msg);
  @override
  String toString() => 'Swallowed error "$message"';
}

class NotImplementedException extends AppException {
  NotImplementedException([Object? msg]) : super(msg ?? 'Not implemented');
  @override
  String toString() => message;
}

class AppInitializationException implements Exception {
  final AppException exception;
  AppInitializationException(this.exception);
  @override
  String toString() => exception.message;
}
