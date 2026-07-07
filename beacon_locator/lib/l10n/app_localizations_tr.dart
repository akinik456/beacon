// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get actionRequired => 'İşlem Gerekli';

  @override
  String get activeWatchers => 'Aktif İzleyenler';

  @override
  String get addAdmin => 'Yönetici ekle';

  @override
  String get addMember => 'Üye Ekle';

  @override
  String get addressNotAvailable => 'Adres mevcut değil';

  @override
  String get addressResolving => 'Adres çözümleniyor...';

  @override
  String get adminName => 'Yönetici İsmi';

  @override
  String get alerts => 'ALARMLAR';

  @override
  String get allPermissionsGranted => 'Tüm İzinler Verildi';

  @override
  String get allowOneMoreAdmin => 'Bir yönetici daha ekle';

  @override
  String get allowOneMoreMember => 'Bir üye daha ekle';

  @override
  String get aNewVer => 'Yeni bir sürüm mevcut. En iyi deneyim için şimdi güncelleyin.';

  @override
  String get appName => 'LynraFamily';

  @override
  String get approve => 'Onay';

  @override
  String get askTheGroup => 'Grup sahibinden LynraFamily\'i yükseltmesini isteyin.';

  @override
  String get askEverybody => 'Herkese \'Beni Ara\' İsteği Gönder';

  @override
  String get atThisLocationNow => 'Bu konumda: Az önce';

  @override
  String atThisLocationMinutes(Object minutes) {
    return 'Bu konumda: $minutes dk';
  }

  @override
  String atThisLocationHours(Object hours) {
    return 'Bu konumda: $hours sa';
  }

  @override
  String atThisLocationHoursMinutes(Object hours, Object minutes) {
    return 'Bu konumda: $hours sa $minutes dk';
  }

  @override
  String get autoStart => 'Otomatik Başlatma';

  @override
  String get backgroundAccessInstructions => 'Açılan ekranda \"LynraFamily Member\" seçeneğini bulun ve arka planda güvenilir çalışması için anahtarı AÇIK konuma getirin.\n\nBu pencere 10 saniye içinde kapanacaktır...';

  @override
  String get backgroundPermissions => 'LynraFamily Member\'ın arka planda çalışabilmesi için aşağıdaki izinlere ihtiyaç vardır.';

  @override
  String get batteryAlertlevel => 'Pil Alarm Seviyesi';

  @override
  String get batteryLowAlert => 'Düşük Pil Alarmı';

  @override
  String get batteryOptimization => 'Pil Kısıtlaması';

  @override
  String get batteryOptimizationDescription => 'Arka planda çalışabilmesi için \"Kısıtlama Yok\" olarak ayarlayın';

  @override
  String get beingWatched => 'İzleniyorsun';

  @override
  String get callme => 'Beni Ara';

  @override
  String get callMeSent => 'Beni Ara Gönderildi';

  @override
  String get callMeSentAll => 'Arama İsteği tüm yöneticilere gönderildi';

  @override
  String get cameraPermissionDesc => 'Sadece QR kodu okutulurken kullanılır.';

  @override
  String get cameraPermissionTitle => 'Kamera izni';

  @override
  String get cancel => 'İptal';

  @override
  String get chooseWhichNotif => 'Bu üyeden hangi bildirimleri almak istediğinizi seçin.';

  @override
  String get cntinue => 'Devam';

  @override
  String get code => 'Kodu';

  @override
  String get confirm => 'Onay';

  @override
  String get connectAMember => 'Bir üyeye bağlan';

  @override
  String get createNewGroup => 'Yeni grup oluştur';

  @override
  String get createOrJoin => 'Yeni bir grup oluşturun veya mevcut bir gruba katılın.';

  @override
  String daysAgo(Object count) {
    return '$count gün önce';
  }

  @override
  String get delete => 'Sil';

  @override
  String get deletePlaceConfirmation => 'Bu yeri silmek istiyor musunuz?';

  @override
  String get disabledByMaster => 'Grup yöneticisi tarafından devre dışı bırakıldı';

  @override
  String get dismiss => 'Kapat';

  @override
  String get enableAutostart => 'LynraFamily Member Otomatik Başlatma Listesine Eklenmeli';

  @override
  String get enteryourname => 'İsminiz (Diğer üyeler bu ismi görür)';

  @override
  String get enterMemberCode => 'Üye Kodunu Girin';

  @override
  String get enterMemberName => 'Üye İsmi Girin';

  @override
  String get familyHome => 'Aile,Ev...';

  @override
  String get feedback => 'Geri Bildirim';

  @override
  String freeTrialDaysLeft(int days) {
    return 'Ücretsiz deneme: $days gün kaldı';
  }

  @override
  String get geofenceAlert => 'Konum Alarmı';

  @override
  String get goPremium => 'Premium\'a geç';

  @override
  String get gpsOffAlert => 'GPS Kapalı Alarmı';

  @override
  String get groupInfo => 'Grup Bilgileri';

  @override
  String get granted => 'Tamam';

  @override
  String get grantRequiredPermissions => 'Gerekli İzinleri Ver';

  @override
  String get group => 'Grup';

  @override
  String get groupCode => 'Grup Kodu';

  @override
  String get groupName => 'Grup İsmi';

  @override
  String get groupQRCode => 'Grup QR Kodu';

  @override
  String get hello => 'Merhaba';

  @override
  String hoursAgo(Object count) {
    return '$count saat önce';
  }

  @override
  String get iUnderstand => 'ANLADIM';

  @override
  String get importantFor => 'Konum isteklerini görebilmek için gereklidir';

  @override
  String isWatchingYourLocation(Object name) {
    return '$name konumunu izliyor.';
  }

  @override
  String get joinGroup => 'Gruba katıl';

  @override
  String get joinInstantlyWithCamera => 'Kamerayla anında katılın';

  @override
  String get joinRequest => 'Gruba Katılma İsteği';

  @override
  String get joinRequestCouldNotBeApproved => 'Katılma isteği onaylanamadı.';

  @override
  String get justNow => 'Az önce';

  @override
  String get language => 'Dil';

  @override
  String get lastKnownLocation => 'Son bilinen konum';

  @override
  String get later => 'DAHA SONRA';

  @override
  String get lifeTimeAccess => 'Ömür boyu erişim';

  @override
  String get locationAccess => 'Konum Erişimi';

  @override
  String get locationAlwaysDescription => '\"Her zaman izin ver\" olarak ayarlayın';

  @override
  String get locationPermissionTitle => 'Konum izni';

  @override
  String get locationPermissionDescription => 'LynraFamily, konumunuzu yalnızca sizinle eşleştirilmiş üyeler arasındaki mesafeyi hesaplamak için kullanır.\n\nKonumunuz üyelerle veya başka kullanıcılarla paylaşılmaz.';

  @override
  String get locationPermissionDescForLocator => 'LynraFamily Member, güvenilir aile üyelerinizin gerektiğinde konumunuzu isteyebilmesi için konum erişimine ihtiyaç duyar.\n\nArka plan konum izni, uygulama kapalı olsa bile bu isteklerin çalışmasını sağlar.\n\nKonumunuz yalnızca güvenilir aile üyelerinizle paylaşılır.';

  @override
  String get locatorGuide1 => 'Konumunuzu paylaşabilmek için önce bir aile grubuna katılmalısınız.';

  @override
  String get locatorGuide2 => 'Eşleştirme isteği alabilmek için Üye Kodunuzu aile yöneticinizle paylaşın.';

  @override
  String get locatorGuide3 => 'Üye Kodunuzu Grup Bilgileri panelini açarak görebilirsiniz.';

  @override
  String get locatorGuide4 => 'Aile yöneticilerinizin size ulaşmasını istediğinizde Beni Ara butonunu kullanabilirsiniz.';

  @override
  String get manufacturerSettings => 'ÜRETİCİ AYARLARI';

  @override
  String get mapbutton => 'Harita';

  @override
  String get master => 'Grup Yöneticisi';

  @override
  String get maxFamilyMembersReached => 'Maximum family members reached';

  @override
  String get maximum5Places => 'En fazla 5 konum kaydedilebilir';

  @override
  String get member => 'Üye';

  @override
  String get members => 'Üyeler';

  @override
  String get memberAlreadyPaired => 'Bu üye zaten listede.';

  @override
  String get memberCode => 'Üye Kodu';

  @override
  String get memberlimitreached => 'Üye Limitine Ulaşıldı';

  @override
  String get memberNotifications => 'Üye Bildirimleri';

  @override
  String get memberNotFound => 'Üye Bulunamadı';

  @override
  String get memberpaired => 'Üye ile Bağlantı Kuruldu';

  @override
  String get memberQRCode => 'Üye QR Kodu';

  @override
  String get memberremoved => 'Üye Kaldırıldı';

  @override
  String get memberSettings => 'Üye Ayarları';

  @override
  String get memoryLock => 'Bellek Kilidi';

  @override
  String get memoryProtection => 'Bellek Koruması';

  @override
  String get memoryProtectionInstructions => 'LynraFamily Member uygulamasının arka planda çalışmaya devam etmesi için lütfen aşağıdaki adımları uygulayın:\n\n• Xiaomi: Güvenlik uygulaması > Hızlandırma > Ayarlar > Uygulama Kilidi > LynraFamily Member uygulamasını etkinleştirin.\n• Diğer Android cihazları: Son Uygulamalar ekranında LynraFamily Member uygulamasının simgesine dokunarak veya uzun basarak Uygulama Bilgileri menüsünü açın.\nÜreticiniz destekliyorsa uygulamayı bellekte tutma / açık tutma seçeneğini etkinleştirin.';

  @override
  String get memberReady => 'Hazır';

  @override
  String minutesAgo(Object count) {
    return '$count dk önce';
  }

  @override
  String get missing => 'Eksik';

  @override
  String get movementAlert => 'Hareket Uyarısı';

  @override
  String get movementDistance => 'Hareket Mesafesi';

  @override
  String multipleWatchersWatchingYourLoc(Object count, Object name) {
    return '$name ve $count kişi daha konumunu izliyor.';
  }

  @override
  String get name => 'isim';

  @override
  String get notify => 'Bildirim';

  @override
  String get noActiveWatchers => 'Aktif izleyen yok';

  @override
  String get noGroupYet => 'Henüz Bir Gruba Girmediniz';

  @override
  String get noPairedMemberYet => 'Eşleştirilmiş Üye Yok';

  @override
  String get noPairedRequester => 'Eşleştirilmiş Yönetici Yok';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationSettingsSaved => 'Bildirim ayarları kaydedildi.';

  @override
  String get notifyBattery => 'Pil seviyesi düşük olduğunda bildir';

  @override
  String get notifyGPS => 'GPS kapatıldığında bildir';

  @override
  String get notifyMovement => 'Hareket algılandığında bildir';

  @override
  String get notifyPlaces => 'Üye belirlenen yerlere girdiğinde veya ayrıldığında bildir';

  @override
  String get offlineNow => 'Az önce';

  @override
  String offlineMinutes(Object minutes) {
    return '$minutes dk';
  }

  @override
  String offlineHours(Object hours) {
    return '$hours sa';
  }

  @override
  String offlineHoursMinutes(Object hours, Object minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get ok => 'Tamam';

  @override
  String get onlyTheMaster => 'Bu ayarları yalnızca grup yöneticisi değiştirebilir.';

  @override
  String get otherApps => 'Diğer Uygulamalar';

  @override
  String get pairedMember => 'Eşleştirilmiş Üye';

  @override
  String get pairedMembers => 'Eşleştirilmiş Üyeler';

  @override
  String get pairingRejected => 'Bağlantı isteği reddedildi';

  @override
  String get pairingRequest => 'Bağlantı isteği';

  @override
  String get pairedRequesters => 'Eşleştirilmiş Yöneticiler';

  @override
  String get pairingRequestPending => 'Bu üyeye gönderilmiş bekleyen bir bağlantı isteği var.';

  @override
  String get permissions => 'İzinler';

  @override
  String get permissionIntroTitle => 'Başlamadan önce';

  @override
  String get permissionIntroSubtitle => 'LynraFamily’nin güvenli ve doğru çalışması için birkaç izne ihtiyacı var.';

  @override
  String get permissionsRequired => 'İzinler Gerekli';

  @override
  String get physicalActivity => 'Fiziksel Aktivite';

  @override
  String get places => 'Yerler';

  @override
  String get placeName => 'Yer adı';

  @override
  String get placeNameHint => 'Ev, Okul, İş yeri...';

  @override
  String get premiumActive => 'Premium aktif';

  @override
  String get placeSaved => 'Konum kaydedildi';

  @override
  String get preventSystemKillDescription => 'Sistemin LynraFamily Member uygulamasını durdurmasını önleyin';

  @override
  String get purchase => 'Satın al';

  @override
  String get quickGuide => 'Hızlı Klavuz';

  @override
  String get rateOnPlayStore => 'Play Store\'da değerlendir';

  @override
  String get receiveCallMe => 'Bu üyeden gelen arama isteklerini alın.';

  @override
  String get receiveGPSalerts => 'GPS kapalı uyarılarını alın';

  @override
  String get receivelowbattery => 'Pil seviyesi düşük uyarısı alın';

  @override
  String get receiveMovement => 'Hareket uyarılarını al';

  @override
  String get reject => 'Reddet';

  @override
  String get rejected => 'REDDEDİLDİ';

  @override
  String get remove => 'Sil';

  @override
  String get removeFromGroup => 'Gruptan çıkar';

  @override
  String get removeMember => 'Üyeyi Kaldır';

  @override
  String get requester => 'Yönetici';

  @override
  String get requesters => 'Yöneticiler';

  @override
  String get requesterGuide1 => 'Bir aile grubu oluşturun veya mevcut bir gruba katılın.';

  @override
  String get requesterGuide2 => 'Üye Kodunu girerek veya QR kodunu tarayarak üyeleri davet edin.';

  @override
  String get requesterGuide3 => 'Konum talep etmeden önce üyelerin eşleştirme isteğinizi onaylamasını bekleyin.';

  @override
  String get requesterGuide4 => 'Canlı Konum ve Beni Ara özelliklerini yalnızca gerektiğinde kullanın.';

  @override
  String get requiredForMotion => 'Hareket algılama için gereklidir.';

  @override
  String get requesterName => 'Yönetici ismi';

  @override
  String get save => 'Kaydet';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get saveMemberLocation => 'Üye konumunu kaydet';

  @override
  String get saveSettings => 'Ayarları Kaydet';

  @override
  String get scanMemberCodeWithCamera => 'Üye kodunu kamera ile taratın';

  @override
  String get scanQRCode => 'QR kodunu tara';

  @override
  String get scanTheMember => 'Üye QR kodunu taratın veya kısa kodunu manuel olarak girin.';

  @override
  String secondsAgo(Object count) {
    return '$count sn önce';
  }

  @override
  String get sendFeedback => 'Geri Bildirim Gönder';

  @override
  String get sendJoinRequest => 'Katılma İsteği Gönder';

  @override
  String get sendPairingRequest => 'Bağlantı isteği gönder';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsSaved => 'Ayarlar kaydedildi';

  @override
  String get sixdigitcode => '6 haneli kod giriniz';

  @override
  String get somePermissions => 'Bazı izinler eksik. Lütfen izinler sayfasını açın ve gerekli izinleri verin.';

  @override
  String get sva => 'Kaydet';

  @override
  String get systemPermissions => 'SİSTEM İZİNLERİ';

  @override
  String get thismember => 'Bu üye listenizden kaldırılacaktır.';

  @override
  String get title => 'LynraFamily';

  @override
  String get titleMember => 'LynraFamily Member';

  @override
  String get trialExpired => 'Deneme süresi sona erdi';

  @override
  String twoWatchersWatchingYourLocation(Object name1, Object name2) {
    return '$name1 ve $name2 konumunu izliyor.';
  }

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get update => 'GÜNCELLE';

  @override
  String get updateAvailable => 'Güncelleme Mevcut';

  @override
  String get upgradeToAddMoreMembers => 'Planınızı yükselterek daha fazla üye ekleyebilirsiniz.';

  @override
  String get upgradeToContinue => 'Aile üyelerinizi takip etmeye devam etmek için Premium\'a yükseltin.';

  @override
  String get version => 'Sürüm';

  @override
  String get viewOnly => 'Görüntüleme Modu';

  @override
  String get waitingForApproval => 'Onay Bekleniyor';

  @override
  String get waitingForLocator => 'Üyenin onay vermesi bekleniyor...';

  @override
  String get wantsYoutoCall => 'Aramanızı istiyor';

  @override
  String watchingLocationSingle(Object name) {
    return '$name konumunu izliyor.';
  }

  @override
  String watchingLocationDouble(Object name1, Object name2) {
    return '$name1 ve $name2 konumunu izliyor.';
  }

  @override
  String watchingLocationMultiple(Object count, Object name) {
    return '$name ve $count kişi daha konumunu izliyor.';
  }

  @override
  String get wellcome => 'Hoşgeldiniz';

  @override
  String get yesterday => 'Dün';

  @override
  String get yourname => 'İsim';

  @override
  String get yourrequest => 'Talebiniz Grup Yöneticisine İletildi.';
}
