// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get upgradeToAddMoreMembers => 'Actualiza tu plan para agregar más miembros.';

  @override
  String freeTrialDaysLeft(int days) {
    return 'Prueba gratuita: quedan $days días';
  }

  @override
  String get placeName => 'Nombre del lugar';

  @override
  String get placeNameHint => 'Casa, Escuela, Trabajo...';

  @override
  String get deletePlaceConfirmation => 'Quieres eliminar este lugar?';

  @override
  String get delete => 'Eliminar';

  @override
  String get groupInfo => 'Información del grupo';

  @override
  String get quickGuide => 'Quick Guide';

  @override
  String get locatorGuide1 => 'Para compartir tu ubicación, primero debes unirte a un grupo familiar.';

  @override
  String get locatorGuide2 => 'Comparte tu Código de Miembro con el administrador de tu familia para recibir una solicitud de vinculación.';

  @override
  String get locatorGuide3 => 'Puedes encontrar tu Código de Miembro abriendo el panel Información del Grupo.';

  @override
  String get locatorGuide4 => 'Utiliza el botón Llámame cuando quieras que los administradores de tu familia se pongan en contacto contigo.';

  @override
  String get requesterGuide1 => 'Crea un grupo familiar o únete a uno existente.';

  @override
  String get requesterGuide2 => 'Invita a los miembros introduciendo su Código de Miembro o escaneando su código QR.';

  @override
  String get requesterGuide3 => 'Espera a que los miembros aprueben tu solicitud de vinculación antes de solicitar su ubicación.';

  @override
  String get requesterGuide4 => 'Utiliza Ubicación en Vivo y Llámame solo cuando sea necesario.';

  @override
  String get aNewVer => 'Hay una nueva versión disponible. Actualiza ahora para disfrutar de la mejor experiencia.';

  @override
  String get addAdmin => 'Agregar administrador';

  @override
  String get addressNotAvailable => 'Dirección no disponible';

  @override
  String get addressResolving => 'Resolviendo dirección...';

  @override
  String get allowOneMoreAdmin => 'Permitir un administrador más';

  @override
  String get allowOneMoreMember => 'Permitir un miembro más';

  @override
  String get askTheGroup => 'Pide al propietario del grupo que actualice LynraFamily.';

  @override
  String get beingWatched => 'Te están observando';

  @override
  String get goPremium => 'Hazte Premium';

  @override
  String get feedback => 'Comentarios';

  @override
  String isWatchingYourLocation(Object name) {
    return '$name está viendo tu ubicación.';
  }

  @override
  String get later => 'MÁS TARDE';

  @override
  String get lifeTimeAccess => 'Acceso de por vida';

  @override
  String get mapbutton => 'Mapa';

  @override
  String multipleWatchersWatchingYourLoc(Object count, Object name) {
    return '$name y $count personas más están viendo tu ubicación.';
  }

  @override
  String get name => 'nombre';

  @override
  String get notify => 'Notificar';

  @override
  String get otherApps => 'Otras aplicaciones';

  @override
  String get places => 'Lugares';

  @override
  String get premiumActive => 'Premium activo';

  @override
  String get purchase => 'Comprar';

  @override
  String get rateOnPlayStore => 'Valorar en Play Store';

  @override
  String get requesterName => 'nombre de administrador';

  @override
  String get save => 'Guardar';

  @override
  String get scanQRCode => 'Escanear código QR';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get settings => 'ajustes';

  @override
  String get trialExpired => 'Período de prueba finalizado';

  @override
  String twoWatchersWatchingYourLocation(Object name1, Object name2) {
    return '$name1 y $name2 están viendo tu ubicación.';
  }

  @override
  String get update => 'ACTUALIZAR';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get version => 'Versión';

  @override
  String watchingLocationSingle(Object name) {
    return '$name está viendo tu ubicación.';
  }

  @override
  String watchingLocationDouble(Object name1, Object name2) {
    return '$name1 y $name2 están viendo tu ubicación.';
  }

  @override
  String watchingLocationMultiple(Object count, Object name) {
    return '$name y $count personas más están viendo tu ubicación.';
  }

  @override
  String get actionRequired => 'Acción requerida';

  @override
  String get activeWatchers => 'Observadores activos';

  @override
  String get addMember => 'Agregar miembro';

  @override
  String get adminName => 'Nombre del administrador';

  @override
  String get alerts => 'ALERTAS';

  @override
  String get allPermissionsGranted => 'Todos los permisos concedidos';

  @override
  String get appName => 'LynraFamily';

  @override
  String get approve => 'Aprobar';

  @override
  String get askEverybody => 'Pedir a todos que me llamen';

  @override
  String get autoStart => 'Inicio automático';

  @override
  String get callMeSent => 'Llamada solicitada.';

  @override
  String get backgroundPermissions => 'LynraFamily Member requiere estos permisos para funcionar en segundo plano.';

  @override
  String get backgroundAccessInstructions => 'En la pantalla inicial, busque \"LynraFamily Member\" y active el interruptor para garantizar la fiabilidad en segundo plano.\n\nEsta ventana se cerrará en 10 segundos...';

  @override
  String get batteryAlertlevel => 'Nivel de alerta de batería';

  @override
  String get batteryLowAlert => 'Alerta de batería baja';

  @override
  String get batteryOptimization => 'Optimización de batería';

  @override
  String get batteryOptimizationDescription => 'Configurar como \"Sin restricciones\" para el funcionamiento en segundo plano';

  @override
  String get callme => 'Llámame';

  @override
  String get callMeSentAll => 'Solicitud de llamada enviada a todos los administradores';

  @override
  String get cameraPermissionTitle => 'Permiso de cámara';

  @override
  String get cameraPermissionDesc => 'Se utiliza solo al escanear un código QR.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get chooseWhichNotif => 'Elija qué notificaciones desea recibir de este miembro.';

  @override
  String get cntinue => 'Continuar';

  @override
  String get code => 'Código';

  @override
  String get confirm => 'Confirmar';

  @override
  String get connectAMember => 'Conectar un miembro';

  @override
  String get createOrJoin => 'Crear un nuevo grupo o unirse a un grupo existente';

  @override
  String get createNewGroup => 'Crear un nuevo grupo';

  @override
  String daysAgo(Object count) {
    return 'hace $count días';
  }

  @override
  String get disabledByMaster => 'Deshabilitado por el administrador';

  @override
  String get dismiss => 'Cerrar';

  @override
  String get enableAutostart => 'Habilitar LynraFamily Member en la lista de inicio automático';

  @override
  String get enteryourname => 'Introduzca su nombre (otros miembros verán este nombre).';

  @override
  String get enterMemberCode => 'Introducir código del miembro';

  @override
  String get enterMemberName => 'Introducir nombre del miembro';

  @override
  String get familyHome => 'Familia, Hogar...';

  @override
  String get hello => 'Hola';

  @override
  String get joinGroup => 'Unirse al grupo';

  @override
  String get joinInstantlyWithCamera => 'Unirse instantáneamente con la cámara';

  @override
  String get joinRequest => 'Solicitud de unión';

  @override
  String get justNow => 'Justo ahora';

  @override
  String get geofenceAlert => 'Alerta de geovalla';

  @override
  String get gpsOffAlert => 'Alerta de GPS desactivado';

  @override
  String get granted => 'Concedido';

  @override
  String get grantRequiredPermissions => 'Conceder permisos requeridos';

  @override
  String get group => 'Grupo';

  @override
  String get groupCode => 'Código del grupo';

  @override
  String get groupQRCode => 'Código QR del grupo';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String hoursAgo(Object count) {
    return 'hace $count hora(s)';
  }

  @override
  String get iUnderstand => 'ENTIENDO';

  @override
  String get importantFor => 'Importante para la visibilidad de solicitudes';

  @override
  String get language => 'Idioma';

  @override
  String get locationAccess => 'Acceso a ubicación';

  @override
  String get locationAlwaysDescription => 'Configurar como \"Permitir siempre\" para el seguimiento';

  @override
  String get locationPermissionTitle => 'Permiso de ubicación';

  @override
  String get locationPermissionDescription => 'LynraFamily Member necesita permiso de ubicación para responder a solicitudes familiares y compartir actualizaciones de ubicación.\n\nEl acceso a la ubicación en segundo plano permite proporcionar actualizaciones incluso cuando la aplicación no está abierta.\n\nSu ubicación solo se comparte con miembros de confianza de su grupo familiar.';

  @override
  String get manufacturerSettings => 'AJUSTES DEL FABRICANTE';

  @override
  String get master => 'Administrador principal';

  @override
  String get maxFamilyMembersReached => 'Se alcanzó el número máximo de miembros';

  @override
  String get maximum5Places => 'Máximo 5 lugares permitidos';

  @override
  String get member => 'Miembro';

  @override
  String get memberCode => 'Código del miembro';

  @override
  String get memberlimitreached => 'Límite de miembros alcanzado';

  @override
  String get memberNotifications => 'Notificaciones del miembro';

  @override
  String get memberNotFound => 'Miembro no encontrado';

  @override
  String get memberpaired => 'Miembro vinculado correctamente';

  @override
  String get memberQRCode => 'Código QR del miembro';

  @override
  String get memberremoved => 'Miembro eliminado';

  @override
  String get memberSettings => 'Configuración del miembro';

  @override
  String get memoryLock => 'Bloqueo de memoria';

  @override
  String get memoryProtection => 'Protección de memoria';

  @override
  String get memoryProtectionInstructions => 'Para mantener LynraFamily Member ejecutándose en segundo plano, siga estos pasos:\n\n• Xiaomi: Aplicación Seguridad > Aumentar velocidad > Ajustes > Bloqueo de aplicaciones > Activar LynraFamily Member.\n• Otros: Abra aplicaciones recientes, mantenga pulsado LynraFamily Member o deslice hacia abajo y toque el icono de bloqueo.\n\nEsto ayuda a evitar que el sistema cierre la aplicación para ahorrar RAM.';

  @override
  String get memberReady => 'Miembro listo';

  @override
  String minutesAgo(Object count) {
    return 'hace $count min';
  }

  @override
  String get missing => 'Falta';

  @override
  String get noActiveWatchers => 'No hay observadores activos';

  @override
  String get noGroupYet => 'Aún no hay grupo';

  @override
  String get noPairedMemberYet => 'Aún no hay miembros vinculados.';

  @override
  String get noPairedRequester => 'No hay administrador vinculado';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationSettingsSaved => 'Configuración de notificaciones guardada';

  @override
  String get notifyBattery => 'Notificar cuando la batería esté baja';

  @override
  String get notifyGPS => 'Notificar cuando el GPS se desactive';

  @override
  String get notifyPlaces => 'Notificar cuando un miembro entre o salga de lugares';

  @override
  String get ok => 'Aceptar';

  @override
  String get onlyTheMaster => 'Solo el administrador principal puede editar esta configuración.';

  @override
  String get pairedMember => 'Miembro vinculado';

  @override
  String get pairedRequesters => 'Administradores vinculados';

  @override
  String get pairingRejected => 'Solicitud de vinculación rechazada';

  @override
  String get pairingRequest => 'Solicitud de vinculación';

  @override
  String get permissionIntroTitle => 'Antes de comenzar';

  @override
  String get permissions => 'Permisos';

  @override
  String get permissionIntroSubtitle => 'LynraFamily necesita algunos permisos para funcionar de forma segura y correcta.';

  @override
  String get permissionsRequired => 'Permisos requeridos';

  @override
  String get physicalActivity => 'Actividad física';

  @override
  String get placeSaved => 'Lugar guardado';

  @override
  String get preventSystemKillDescription => 'Evitar que el sistema cierre LynraFamily Member';

  @override
  String get receiveCallMe => 'Recibir solicitudes de llamada de este miembro';

  @override
  String get receiveGPSalerts => 'Recibir alertas de GPS desactivado';

  @override
  String get receivelowbattery => 'Recibir alertas de batería baja';

  @override
  String get reject => 'Rechazar';

  @override
  String get rejected => 'RECHAZADO';

  @override
  String get remove => 'Eliminar';

  @override
  String get removeMember => 'Eliminar miembro';

  @override
  String get requester => 'Ejecutivo';

  @override
  String get requesters => 'Administradores';

  @override
  String get requiredForMotion => 'Requerido para detección de movimiento';

  @override
  String get saveMemberLocation => 'Guardar ubicación del miembro como lugar';

  @override
  String get saveSettings => 'Guardar configuración';

  @override
  String get scanMemberCodeWithCamera => 'Escanear código del miembro con la cámara';

  @override
  String get scanQRcode => 'Escanear código QR';

  @override
  String get scanTheMember => 'Escanee el código QR del miembro o introduzca su código corto manualmente.';

  @override
  String get sendPairingRequest => 'Enviar solicitud de vinculación';

  @override
  String secondsAgo(Object count) {
    return 'hace $count seg';
  }

  @override
  String get settingsSaved => 'Configuración guardada';

  @override
  String get sixdigitcode => 'Introduzca un código de 6 dígitos';

  @override
  String get somePermissions => 'Faltan algunos permisos. Abra la página de permisos y conceda los permisos requeridos.';

  @override
  String get sva => 'Guardar';

  @override
  String get saved => 'Guardado';

  @override
  String get systemPermissions => 'PERMISOS DEL SISTEMA';

  @override
  String get thismember => 'Este miembro será eliminado de su lista vinculada.';

  @override
  String get title => 'LynraFamily';

  @override
  String get unknown => 'Desconocido';

  @override
  String get titleMember => 'LynraFamily Member';

  @override
  String get viewOnly => 'Solo lectura';

  @override
  String get waitingForApproval => 'Esperando aprobación';

  @override
  String get waitingForLocator => 'Esperando aprobación del miembro...';

  @override
  String get wantsYoutoCall => 'Quiere que lo llame';

  @override
  String get wellcome => 'Bienvenido';

  @override
  String get yesterday => 'Ayer';

  @override
  String get yourname => 'Nombre';

  @override
  String get yourrequest => 'Su solicitud ha sido enviada al administrador principal del grupo.';
}
