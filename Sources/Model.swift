import Foundation
import Observation
import SwiftUI
import AppKit

// MARK: - Локализация (RU / EN)

@Observable
final class L10n {
    static let shared = L10n()

    var lang: String = UserDefaults.standard.string(forKey: "appLang") ?? "ru" {
        didSet { UserDefaults.standard.set(lang, forKey: "appLang") }
    }

    func t(_ key: String) -> String {
        if lang == "ru" { return L10n.ru[key] ?? key }
        return L10n.en[key] ?? L10n.ru[key] ?? key
    }

    /// Форматированная строка: L10n.shared.f("misc.selected", 3)
    func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), locale: .current, arguments: args)
    }

    static let ru: [String: String] = [
        "sec.overview": "Обзор диска", "sec.largeFiles": "Большие файлы",
        "sec.folders": "Тяжёлые папки", "sec.map": "Карта диска", "sec.duplicates": "Дубликаты",
        "sec.apps": "Приложения", "sec.downloads": "Загрузки",
        "sec.junk": "Системный мусор", "sec.startup": "Автозагрузка",
        "sec.trash": "Корзина", "sec.history": "История", "sec.settings": "Настройки",
        "menu.navigate": "Переход", "menu.find.search": "Найти в списке…",
        "sub.overview": "Всё пространство. Под вашим контролем.",
        "sub.largeFiles": "Файлы больше 50 МБ, которые занимают место.",
        "sub.folders": "Не один большой файл, а папки, которые набрали вес по мелочи.",
        "sub.map": "Каждая папка — блок пропорциональный её весу. Нажмите, чтобы зайти внутрь.",
        "sub.duplicates": "Одна копия нужна. Остальные — нет.",
        "sub.apps": "Удаляйте приложения вместе с остаточными файлами.",
        "sub.downloads": "Файлы старше 30 дней. Всё важное уже сохранено?",
        "sub.junk": "Больше места. Без риска для ваших файлов.",
        "sub.startup": "Решайте, что запускается вместе с вашим Mac.",
        "sub.trash": "Последняя остановка перед удалением.",
        "sub.history": "Каждая очистка — немного больше свободы.",
        "sub.settings": "Оформление, язык, разрешения и информация о приложении.",
        "btn.scan": "Сканировать", "btn.rescan": "Сканировать заново",
        "btn.selectAll": "Выбрать все", "btn.deselect": "Снять выбор",
        "btn.delete": "Удалить выбранное", "btn.cancel": "Отмена",
        "misc.selected": "Выбрано", "misc.toTrashNote": "Файлы сначала попадут в Корзину",
        "theme.light": "Светлая", "theme.dark": "Тёмная", "theme.system": "Как в системе",
        "apps.unused": "Не открывались 6+ мес: %d · %@",
        "apps.sort.size": "По размеру", "apps.sort.unused": "Давно не открывались",
        "theme.systemShort": "Авто",
        "access.recent": "открывался недавно",
        "settings.appearance": "Оформление", "settings.theme": "Тема интерфейса",
        "settings.language": "Язык интерфейса",
        "settings.permissions": "Разрешения",
        "settings.perm.fda": "Полный доступ к диску",
        "settings.perm.fda.desc": "Сканирование защищённых папок (Safari, Почта, Сообщения)",
        "settings.perm.files": "Файлы и папки",
        "settings.perm.files.desc": "Доступ к «Документам», «Загрузкам» и «Рабочему столу»",
        "settings.perm.media": "Медиатека и Apple Music",
        "settings.perm.media.desc": "Учёт медиатеки при обзоре диска",
        "settings.configure": "Настроить",
        "perm.granted": "выдано", "perm.denied": "отклонено", "perm.unknown": "не запрошено",
        "settings.updates": "Обновления",
        "settings.checkUpdates": "Проверить обновления",
        "settings.latestVersion": "У вас последняя версия",
        "upd.checking": "Проверяю…", "upd.available": "Доступна %@",
        "upd.download": "Скачать", "upd.failed": "Не удалось проверить",
        "upd.downloadInstall": "Скачать и установить",
        "upd.downloading": "Скачиваю…", "upd.installing": "Устанавливаю…",
        "upd.ready": "Обновление готово", "upd.relaunch": "Перезапустить",
        "upd.installFailed": "Не удалось установить",
        "settings.installApp": "Установка в «Программы»",
        "settings.installAppDesc": "Запуск из Launchpad и автообновления",
        "settings.installFailed": "Не удалось — перетащите вручную",
        "btn.install": "Установить",
        "settings.menuBar": "Иконка в меню-баре",
        "settings.dockIcon": "Иконка в Dock",
        "settings.mbicon": "Стиль иконки",
        "mbicon.trash": "Мусорка", "mbicon.rotor": "Ротор двигателя",
        "mbicon.coffee": "Кофе", "mbicon.drop": "Капля",
        "mbicon.newton": "Маятник Ньютона",
        "mbicon.sheep": "Овечка", "mbicon.radiation": "Радиация",
        "menubar.free": "Свободно %@ из %@",
        "menubar.open": "Открыть Mac Cleaner",
        "menubar.quit": "Выйти",
        "ob.welcome": "Добро пожаловать",
        "ob.subtitle": "Найдём, что съедает место на диске, и безопасно уберём лишнее.",
        "ob.f1": "Обзор и карта диска — видно, куда ушли гигабайты",
        "ob.f2": "Большие файлы, дубликаты, кэши и остатки приложений",
        "ob.f3": "Удаление только через Корзину — всё можно вернуть",
        "ob.perm": "Один важный шаг",
        "ob.permDesc": "Выдайте Полный доступ к диску — иначе часть папок останется невидимой для сканирования.",
        "ob.grant": "Выдать доступ",
        "ob.start": "Поехали",
        "settings.version": "Версия", "settings.about": "О приложении",
        "settings.author": "Автор", "settings.authorName": "Stepan Trushin",
        "status.scanning": "Сканирую… %d файлов", "status.today": "Обновлено сегодня, %@",
        "status.date": "Обновлено %@", "status.ready": "Готов к работе",
        "btn.update": "Обновить", "btn.showFiles": "Посмотреть файлы", "btn.hide": "Скрыть",
        "btn.deleteApp": "Удалить…", "btn.openTrash": "Открыть Корзину",
        "btn.selectDupes": "Выбрать лишние", "btn.selectAllDupes": "Выбрать все лишние",
        "btn.scanAll": "Сканировать всё", "btn.findDupes": "Искать дубликаты",
        "btn.toOverview": "К обзору диска",
        "misc.scanning": "Сканирую…", "misc.checked": "Проверено %d файлов",
        "hero.caption": "МЕСТО ДЛЯ ВАЖНОГО", "hero.freeOf": "свободно из %@",
        "hero.used": "%@ занято",
        "hero.lastToday": "Последнее сканирование — сегодня в %@",
        "hero.lastDate": "Последнее сканирование — %@",
        "scan.title": "Изучаю ваш диск", "scan.eta": "Это занимает 1–2 минуты",
        "scan.bg": "Можно продолжать работать",
        "details.title": "Ваш диск в деталях", "details.count": "9 категорий",
        "cat.system": "Система", "cat.free": "Свободно",
        "next.title": "Что дальше?",
        "sort.size": "Размер", "sort.age": "Давность", "sort.big": "Большие", "sort.old": "Старые",
        "misc.filesCount": "%d файлов · %@",
        "dlg.trashTitle": "Переместить в Корзину?",
        "dlg.trashNote": "Файлы не будут удалены безвозвратно. Вы сможете восстановить их из Корзины.",
        "dlg.emptyTrashTitle": "Очистить Корзину?",
        "dlg.emptyTrashNote": "Файлы будут удалены безвозвратно. Это действие нельзя отменить.",
        "dlg.confirmTrash": "В Корзину (%@)", "dlg.confirmEmpty": "Очистить Корзину",
        "toast.restorable": "Можно восстановить, пока Корзина не очищена.",
        "toast.freed": "Освобождено %@ — всё в Корзине",
        "toast.partial": "Перемещено %d, не удалось: %d (заняты системой)",
        "toast.trashEmptied": "Корзина очищена",
        "toast.trashFail": "Не удалось очистить Корзину — сделайте это через Finder",
        "dup.groups": "%d групп дубликатов",
        "dup.free": "Можно освободить %@ · оригиналы останутся на месте",
        "dup.waste": "лишние %@", "dup.copies": "%d копии × %@",
        "dup.note": "Сравнение по содержимому, а не только по имени файла",
        "dup.empty.t": "Дубликатов не найдено",
        "dup.empty.s": "Одинаковых файлов больше 30 МБ нет.",
        "dup.idle.t": "Поиск ещё не запускался",
        "dup.idle.s": "Сравниваются файлы больше 30 МБ по содержимому (SHA-256).",
        "apps.count": "%d приложения · %@", "apps.scanning": "Сканирую приложения и их остатки…",
        "apps.none": "Приложений не найдено",
        "orph.title": "Сироты", "orph.count": "Остатки %d объектов · %@",
        "orph.desc": "Настройки, кэши и служебные файлы удалённых приложений.",
        "orph.none.t": "Остатков не найдено",
        "orph.none.s": "Данных удалённых приложений в библиотеке нет.",
        "uninst.title": "Удалить %@?", "uninst.sub": "Приложение и связанные файлы",
        "uninst.pick": "Выберите, что переместить в Корзину.",
        "uninst.none": "Остатков не найдено — будет удалено только само приложение.",
        "uninst.note": "Файлы можно восстановить из Корзины.",
        "dl.scanning": "Ищу старые файлы…",
        "dl.empty.t": "Старых загрузок нет",
        "dl.empty.s": "В папке «Загрузки» только свежие файлы.",
        "junk.badge": "проверь вручную", "junk.notScanned": "не сканировано",
        "junk.denied": "доступ закрыт", "junk.clean": "Чисто — ничего не найдено.",
        "junk.selCount": "выбрано %d из %d",
        "junk.caches.t": "Кэши приложений", "junk.caches.s": "~/Library/Caches — приложения создадут заново",
        "junk.logs.t": "Логи", "junk.logs.s": "Журналы из ~/Library/Logs",
        "junk.xcode.t": "Xcode и симуляторы", "junk.xcode.s": "DerivedData и кэши — пересоздаются при сборке",
        "junk.pkgman.t": "Кэши пакетных менеджеров", "junk.pkgman.s": "npm, pip, bun, yarn, Homebrew, Gradle",
        "junk.node_modules.t": "node_modules в проектах", "junk.node_modules.s": "Восстанавливаются командой npm install",
        "junk.mobilesync.t": "Бэкапы iPhone и iPad", "junk.mobilesync.s": "Старые бэкапы устройств из MobileSync — проверь, какие ещё нужны",
        "junk.mail.t": "Вложения почты", "junk.mail.s": "Копии открытых вложений — оригиналы остаются в письмах",
        "junk.projjunk.t": "Сборки проектов", "junk.projjunk.s": "dist, .next, target, build, Pods, venv — пересоздаются при сборке",
        "junk.docker.t": "Docker", "junk.docker.s": "Виртуальный диск и кэши Docker Desktop — закрой Docker перед удалением",
        "search.placeholder": "Поиск по имени или пути", "search.empty": "Ничего не найдено по запросу «%@»",
        "start.broken": "программа удалена",
        "map.title": "Карта диска", "map.back": "Весь диск", "map.other": "Остальное",
        "map.hint": "Нажмите на блок, чтобы посмотреть, что внутри",
        "tm.title": "Снимки Time Machine", "tm.none": "снимков нет",
        "tm.count": "%d шт. · последний: %@",
        "tm.desc": "macOS удаляет их автоматически при нехватке места",
        "start.banner.t": "Быстрый старт без лишнего",
        "start.banner.s": "Удаление агента — только в Корзину, при необходимости его можно вернуть на место.",
        "start.footer": "%d агентов · выберите лишние и удалите в Корзину",
        "start.empty.t": "Сторонних агентов автозагрузки нет",
        "start.empty.s": "В ~/Library/LaunchAgents чисто.",
        "trash.count": "%d элем. в Корзине",
        "trash.note": "После очистки восстановить файлы не получится.",
        "trash.recent": "Недавно перемещены",
        "trash.clean.t": "Здесь чисто",
        "trash.clean.s": "Корзина пуста — всё лишнее уже позади.\nОтличный момент, чтобы заняться важным.",
        "trash.denied": "macOS не даёт приложению читать содержимое Корзины — система её защищает. Очистить Корзину можно кнопкой ниже (она работает через Finder).",
        "trash.emptyBtn": "Очистить корзину…", "trash.clear": "Очистить",
        "hist.freed": "освобождено всего", "hist.runs": "очисток",
        "hist.freeChart": "Свободное место", "hist.growth": "С прошлого сканирования",
        "hist.growthUp": "выросло", "hist.growthDown": "уменьшилось",
        "hist.items": "элементов в Корзине", "hist.row": "%d элем. — в Корзине",
        "hist.note": "Файлы можно восстановить из Корзины, пока она не очищена.",
        "hist.empty.t": "Пока пусто", "hist.empty.s": "Здесь появятся записи после первой очистки.",
        "empty.scanFirst.t": "Диск ещё не просканирован",
        "empty.scanLarge.s": "Запустите сканирование, чтобы увидеть большие файлы.",
        "empty.scanFolders.s": "Запустите сканирование, чтобы найти самые тяжёлые папки.",
        "empty.none.t": "Ничего лишнего",
        "empty.noneLarge.s": "Файлов больше 50 МБ не найдено.\nНа вашем Mac есть место для нового.",
        "empty.noFolders.t": "Тяжёлых папок не найдено",
        "empty.noFolders.s": "Нет папок больше 100 МБ в домашней директории.",
        "empty.cat.t": "Нет файлов для показа",
        "empty.cat.s": "В этой категории нет объектов больше 2 МБ.",
        "empty.pressScan": "Нажмите «Сканировать»", "empty.pressUpdate": "Нажмите «Обновить»",
        "folders.count": "%d папок · %@", "folders.expand": "Показать, что внутри",
        "folders.counting": "Считаю размеры…", "folders.empty": "Пусто или файлы меньше 64 КБ",
        "detail.back": "Обзор диска", "help.finder": "Показать в Finder",
        "hint.downloads": "%@ старше 30 дней", "hint.trash": "%@ — можно очистить",
        "hint.junk": "можно освободить %@", "hint.dupes": "%d групп · лишние %@",
        "hint.topFolder": "«%@» весит %@", "hint.dupesGeneric": "поиск одинаковых файлов",
        "hint.junkGeneric": "кэши, логи, пакеты",
        "catdetail.sub": "%@ · %@ · %d файлов",
        "backups.note": "бэкап устройства",
        "dup.scanning": "Сравниваю содержимое файлов…", "misc.error": "Ошибка: %@",
        "catname.video": "Видео", "catname.images": "Образы и фото",
        "catname.archives": "Архивы и образы", "catname.docs": "Документы",
        "catname.apps": "Приложения", "catname.dev": "Разработка", "catname.other": "Другое",
        "help.deselect": "Снять выбор со всех файлов",
        "help.catOpen": "Открыть файлы категории «%@»",
        "help.finderOpen": "Открыть в Finder и посмотреть содержимое",
        "help.tapOpen": "нажмите, чтобы открыть",
        "hint.dl.title": "Старые загрузки",
        "sec.extensions": "Расширения", "sec.monitor": "Мониторинг",
        "sub.extensions": "Quick Look, плагины и службы. Отключайте лишнее.",
        "sub.monitor": "Процессор, память, батарея и нагрев в реальном времени.",
        "junk.crashlogs.t": "Крашлоги", "junk.crashlogs.s": "Отчёты о сбоях приложений из DiagnosticReports",
        "junk.partial.t": "Недокачки и виндовый мусор", "junk.partial.s": ".download, .crdownload, .part, Thumbs.db, desktop.ini",
        "junk.plist.t": "Битые настройки", "junk.plist.s": "Повреждённые .plist — приложение создаст новые",
        "junk.privacy.t": "Приватность браузеров", "junk.privacy.s": "История и куки — закройте браузер перед удалением",
        "note.partial": "Незавершённая загрузка",
        "note.windows": "Служебный файл Windows",
        "note.plist": "Файл не читается — приложение создаст новый",
        "note.history": "История посещений — браузер создаст новый файл",
        "note.cookies": "Куки — сайты попросят войти заново",
        "note.formhistory": "Автозаполнение форм",
        "ext.banner.t": "Расширения работают в фоне",
        "ext.banner.s": "Удаление — только в Корзину: вернёте на место, если что-то перестанет работать.",
        "ext.quicklook": "Quick Look",
        "ext.plugins": "Интернет-плагины",
        "ext.services": "Службы",
        "ext.prefpanes": "Панели настроек",
        "ext.spotlight": "Импортёры Spotlight",
        "ext.empty.t": "Сторонних расширений нет",
        "ext.empty.s": "Quick Look, плагины и службы чисты.",
        "ext.footer": "%d расширений · %@",
        "uninst.resetData": "Сбросить (%@)",
        "uninst.resetHint": "Сброс удаляет только данные — приложение останется на месте.",
        "menubar.trash": "Корзина: %@",
        "mon.cpu": "Процессор", "mon.memory": "Память", "mon.battery": "Батарея",
        "mon.thermal": "Нагрев", "mon.system": "Система", "mon.disk": "Диск",
        "mon.loadAvg": "Нагрузка: %@ · %@ · %@",
        "mon.cores": "%d ядер",
        "mon.usedOf": "%@ из %@",
        "mon.swap": "Подкачка: %@",
        "mon.charging": "заряжается", "mon.discharging": "от батареи",
        "mon.noBattery": "Батареи нет — питание от сети",
        "mon.thermal.nominal": "Нормальный",
        "mon.thermal.fair": "Умеренный",
        "mon.thermal.serious": "Высокий — Mac замедляется",
        "mon.thermal.critical": "Критический!",
        "mon.tempNote": "Точная температура и обороты вентиляторов на Apple Silicon доступны только с правами администратора — поэтому показываем оценку нагрева от самой системы.",
        "mon.uptime": "Аптайм: %@",
        "mon.mac": "macOS %@ · %@",
        "mon.freeOf": "%@ свободно из %@",
        "mb.network": "Сеть",
        "mb.ip": "Локальный IP: %@",
        "mb.down": "↓ %@/с",
        "mb.up": "↑ %@/с",
        "mb.pubip": "Внешний IP: %@ %@",
        "mon.ram": "%@ ОЗУ",
        "mb.offline": "Нет соединения",
    ]

    static let en: [String: String] = [
        "sec.overview": "Disk Overview", "sec.largeFiles": "Large Files",
        "sec.folders": "Heavy Folders", "sec.map": "Disk Map", "sec.duplicates": "Duplicates",
        "sec.apps": "Applications", "sec.downloads": "Downloads",
        "sec.junk": "System Junk", "sec.startup": "Login Items",
        "sec.trash": "Trash", "sec.history": "History", "sec.settings": "Settings",
        "menu.navigate": "Navigate", "menu.find.search": "Find in List…",
        "sub.overview": "All your space. Under your control.",
        "sub.largeFiles": "Files over 50 MB taking up space.",
        "sub.folders": "Not one big file — folders that gained weight byte by byte.",
        "sub.map": "Every folder is a block sized by its weight. Click to look inside.",
        "sub.duplicates": "One copy is enough. The rest can go.",
        "sub.apps": "Remove apps together with their leftover files.",
        "sub.downloads": "Files older than 30 days. Everything important saved?",
        "sub.junk": "More space. No risk to your files.",
        "sub.startup": "Choose what launches with your Mac.",
        "sub.trash": "Last stop before deletion.",
        "sub.history": "Every cleanup frees a bit more space.",
        "sub.settings": "Appearance, language, permissions and app info.",
        "btn.scan": "Scan", "btn.rescan": "Rescan",
        "btn.selectAll": "Select all", "btn.deselect": "Deselect",
        "btn.delete": "Delete selected", "btn.cancel": "Cancel",
        "misc.selected": "Selected", "misc.toTrashNote": "Files go to the Trash first",
        "theme.light": "Light", "theme.dark": "Dark", "theme.system": "System",
        "apps.unused": "Unused for 6+ mo: %d · %@",
        "apps.sort.size": "By size", "apps.sort.unused": "Longest unused",
        "theme.systemShort": "Auto",
        "access.recent": "opened recently",
        "settings.appearance": "Appearance", "settings.theme": "Interface theme",
        "settings.language": "Interface language",
        "settings.permissions": "Permissions",
        "settings.perm.fda": "Full Disk Access",
        "settings.perm.fda.desc": "Scan protected folders (Safari, Mail, Messages)",
        "settings.perm.files": "Files and Folders",
        "settings.perm.files.desc": "Access to Documents, Downloads and Desktop",
        "settings.perm.media": "Media & Apple Music",
        "settings.perm.media.desc": "Media library stats in disk overview",
        "settings.configure": "Configure",
        "perm.granted": "granted", "perm.denied": "denied", "perm.unknown": "not asked",
        "settings.updates": "Updates",
        "settings.checkUpdates": "Check for updates",
        "settings.latestVersion": "You're up to date",
        "upd.checking": "Checking…", "upd.available": "%@ available",
        "upd.download": "Download", "upd.failed": "Check failed",
        "upd.downloadInstall": "Download & Install",
        "upd.downloading": "Downloading…", "upd.installing": "Installing…",
        "upd.ready": "Update ready", "upd.relaunch": "Relaunch",
        "upd.installFailed": "Install failed",
        "settings.installApp": "Install to Applications",
        "settings.installAppDesc": "Launch from Launchpad and auto-update",
        "settings.installFailed": "Failed — drag it manually",
        "btn.install": "Install",
        "settings.menuBar": "Menu bar icon",
        "settings.dockIcon": "Dock icon",
        "settings.mbicon": "Icon style",
        "mbicon.trash": "Trash", "mbicon.rotor": "Engine rotor",
        "mbicon.coffee": "Coffee", "mbicon.drop": "Drop",
        "mbicon.newton": "Newton's cradle",
        "mbicon.sheep": "Sheep", "mbicon.radiation": "Radiation",
        "menubar.free": "%@ free of %@",
        "menubar.open": "Open Mac Cleaner",
        "menubar.quit": "Quit",
        "ob.welcome": "Welcome",
        "ob.subtitle": "We'll find what's eating your disk space and help you remove it safely.",
        "ob.f1": "Disk overview and map — see where your gigabytes went",
        "ob.f2": "Large files, duplicates, caches and app leftovers",
        "ob.f3": "Everything goes to Trash first — nothing is lost forever",
        "ob.perm": "One important step",
        "ob.permDesc": "Grant Full Disk Access — otherwise some folders stay invisible to scans.",
        "ob.grant": "Grant Access",
        "ob.start": "Let's Go",
        "settings.version": "Version", "settings.about": "About",
        "settings.author": "Author", "settings.authorName": "Stepan Trushin",
        "status.scanning": "Scanning… %d files", "status.today": "Updated today at %@",
        "status.date": "Updated %@", "status.ready": "Ready",
        "btn.update": "Refresh", "btn.showFiles": "Show files", "btn.hide": "Hide",
        "btn.deleteApp": "Delete…", "btn.openTrash": "Open Trash",
        "btn.selectDupes": "Select duplicates", "btn.selectAllDupes": "Select all duplicates",
        "btn.scanAll": "Scan all", "btn.findDupes": "Find duplicates",
        "btn.toOverview": "Back to overview",
        "misc.scanning": "Scanning…", "misc.checked": "%d files checked",
        "hero.caption": "ROOM FOR WHAT MATTERS", "hero.freeOf": "free of %@",
        "hero.used": "%@ used",
        "hero.lastToday": "Last scan — today at %@",
        "hero.lastDate": "Last scan — %@",
        "scan.title": "Analyzing your disk", "scan.eta": "Takes 1–2 minutes",
        "scan.bg": "You can keep working",
        "details.title": "Your disk in detail", "details.count": "9 categories",
        "cat.system": "System", "cat.free": "Free",
        "next.title": "What's next?",
        "sort.size": "Size", "sort.age": "Age", "sort.big": "Largest", "sort.old": "Oldest",
        "misc.filesCount": "%d files · %@",
        "dlg.trashTitle": "Move to Trash?",
        "dlg.trashNote": "Files won't be erased permanently. You can restore them from the Trash.",
        "dlg.emptyTrashTitle": "Empty Trash?",
        "dlg.emptyTrashNote": "Files will be permanently deleted. This cannot be undone.",
        "dlg.confirmTrash": "Move to Trash (%@)", "dlg.confirmEmpty": "Empty Trash",
        "toast.restorable": "Restorable until the Trash is emptied.",
        "toast.freed": "Freed %@ — all in Trash",
        "toast.partial": "Moved %d, failed: %d (in use)",
        "toast.trashEmptied": "Trash emptied",
        "toast.trashFail": "Couldn't empty the Trash — do it via Finder",
        "dup.groups": "%d duplicate groups",
        "dup.free": "Can free %@ · originals stay in place",
        "dup.waste": "%@ redundant", "dup.copies": "%d copies × %@",
        "dup.note": "Compared by content, not just file name",
        "dup.empty.t": "No duplicates found",
        "dup.empty.s": "No identical files over 30 MB.",
        "dup.idle.t": "Not searched yet",
        "dup.idle.s": "Files over 30 MB compared by content (SHA-256).",
        "apps.count": "%d apps · %@", "apps.scanning": "Scanning apps and leftovers…",
        "apps.none": "No applications found",
        "orph.title": "Orphans", "orph.count": "Leftovers of %d items · %@",
        "orph.desc": "Settings, caches and service files of removed apps.",
        "orph.none.t": "No leftovers found",
        "orph.none.s": "No data from removed apps.",
        "uninst.title": "Delete %@?", "uninst.sub": "The app and related files",
        "uninst.pick": "Choose what to move to Trash.",
        "uninst.none": "No leftovers — only the app itself will be removed.",
        "uninst.note": "Files can be restored from the Trash.",
        "dl.scanning": "Looking for old files…",
        "dl.empty.t": "No old downloads",
        "dl.empty.s": "Only fresh files in Downloads.",
        "junk.badge": "review manually", "junk.notScanned": "not scanned",
        "junk.denied": "access denied", "junk.clean": "Clean — nothing found.",
        "junk.selCount": "%d of %d selected",
        "junk.caches.t": "App Caches", "junk.caches.s": "~/Library/Caches — apps recreate them",
        "junk.logs.t": "Logs", "junk.logs.s": "Logs from ~/Library/Logs",
        "junk.xcode.t": "Xcode & Simulators", "junk.xcode.s": "DerivedData and caches — recreated on build",
        "junk.pkgman.t": "Package manager caches", "junk.pkgman.s": "npm, pip, bun, yarn, Homebrew, Gradle",
        "junk.node_modules.t": "node_modules in projects", "junk.node_modules.s": "Restored with npm install",
        "junk.mobilesync.t": "iPhone & iPad backups", "junk.mobilesync.s": "Old device backups from MobileSync — check which you still need",
        "junk.mail.t": "Mail attachments", "junk.mail.s": "Copies of opened attachments — originals stay in messages",
        "junk.projjunk.t": "Project build junk", "junk.projjunk.s": "dist, .next, target, build, Pods, venv — recreated on build",
        "junk.docker.t": "Docker", "junk.docker.s": "Docker Desktop VM disk and caches — quit Docker before deleting",
        "search.placeholder": "Search by name or path", "search.empty": "Nothing found for “%@”",
        "start.broken": "program missing",
        "map.title": "Disk Map", "map.back": "Entire disk", "map.other": "Other",
        "map.hint": "Click a block to see what's inside",
        "tm.title": "Time Machine snapshots", "tm.none": "no snapshots",
        "tm.count": "%d · latest: %@",
        "tm.desc": "macOS deletes them automatically when space runs low",
        "start.banner.t": "Fast start without clutter",
        "start.banner.s": "Agents go to Trash — you can put them back anytime.",
        "start.footer": "%d agents · select the unneeded and move to Trash",
        "start.empty.t": "No third-party login agents",
        "start.empty.s": "~/Library/LaunchAgents is clean.",
        "trash.count": "%d items in Trash",
        "trash.note": "Files can't be restored after emptying.",
        "trash.recent": "Recently moved",
        "trash.clean.t": "All clean",
        "trash.clean.s": "Trash is empty — all the clutter is gone.\nA great moment to focus on what matters.",
        "trash.denied": "macOS protects the Trash from apps. You can still empty it with the button below (works via Finder).",
        "trash.emptyBtn": "Empty Trash…", "trash.clear": "Empty",
        "hist.freed": "total freed", "hist.runs": "cleanups",
        "hist.freeChart": "Free space", "hist.growth": "Since last scan",
        "hist.growthUp": "grew", "hist.growthDown": "shrank",
        "hist.items": "items in Trash", "hist.row": "%d items — in Trash",
        "hist.note": "Files can be restored from the Trash until it's emptied.",
        "hist.empty.t": "Nothing yet", "hist.empty.s": "Records will appear after your first cleanup.",
        "empty.scanFirst.t": "Disk not scanned yet",
        "empty.scanLarge.s": "Run a scan to see large files.",
        "empty.scanFolders.s": "Run a scan to find the heaviest folders.",
        "empty.none.t": "Nothing to clean",
        "empty.noneLarge.s": "No files over 50 MB.\nYour Mac has room for new things.",
        "empty.noFolders.t": "No heavy folders",
        "empty.noFolders.s": "No folders over 100 MB in your home directory.",
        "empty.cat.t": "No files to show",
        "empty.cat.s": "No items over 2 MB in this category.",
        "empty.pressScan": "Press “Scan”", "empty.pressUpdate": "Press “Refresh”",
        "folders.count": "%d folders · %@", "folders.expand": "Show contents",
        "folders.counting": "Calculating sizes…", "folders.empty": "Empty or files under 64 KB",
        "detail.back": "Disk Overview", "help.finder": "Reveal in Finder",
        "hint.downloads": "%@ older than 30 days", "hint.trash": "%@ — can be emptied",
        "hint.junk": "can free %@", "hint.dupes": "%d groups · %@ redundant",
        "hint.topFolder": "“%@” weighs %@", "hint.dupesGeneric": "find identical files",
        "hint.junkGeneric": "caches, logs, packages",
        "catdetail.sub": "%@ · %@ · %d files",
        "backups.note": "device backup",
        "dup.scanning": "Comparing file contents…", "misc.error": "Error: %@",
        "catname.video": "Video", "catname.images": "Photos & Images",
        "catname.archives": "Archives & Disk Images", "catname.docs": "Documents",
        "catname.apps": "Applications", "catname.dev": "Development", "catname.other": "Other",
        "help.deselect": "Clear selection",
        "help.catOpen": "Open files in “%@”",
        "help.finderOpen": "Open in Finder to inspect",
        "help.tapOpen": "click to open",
        "hint.dl.title": "Old downloads",
        "sec.extensions": "Extensions", "sec.monitor": "Monitor",
        "sub.extensions": "Quick Look, plug-ins and services. Disable what you don't need.",
        "sub.monitor": "CPU, memory, battery and thermal state in real time.",
        "junk.crashlogs.t": "Crash logs", "junk.crashlogs.s": "App crash reports from DiagnosticReports",
        "junk.partial.t": "Partial downloads & Windows junk", "junk.partial.s": ".download, .crdownload, .part, Thumbs.db, desktop.ini",
        "junk.plist.t": "Broken preferences", "junk.plist.s": "Corrupted .plist files — apps will recreate them",
        "junk.privacy.t": "Browser privacy", "junk.privacy.s": "History and cookies — quit the browser before deleting",
        "note.partial": "Incomplete download",
        "note.windows": "Windows service file",
        "note.plist": "Unreadable — the app will create a fresh one",
        "note.history": "Browsing history — the browser will create a new file",
        "note.cookies": "Cookies — sites will ask you to sign in again",
        "note.formhistory": "Form autofill history",
        "ext.banner.t": "Extensions run in the background",
        "ext.banner.s": "Removal goes to Trash only — put anything back if something stops working.",
        "ext.quicklook": "Quick Look",
        "ext.plugins": "Internet plug-ins",
        "ext.services": "Services",
        "ext.prefpanes": "Preference panes",
        "ext.spotlight": "Spotlight importers",
        "ext.empty.t": "No third-party extensions",
        "ext.empty.s": "Quick Look, plug-ins and services are clean.",
        "ext.footer": "%d extensions · %@",
        "uninst.resetData": "Reset (%@)",
        "uninst.resetHint": "Reset removes only the data — the app stays in place.",
        "menubar.trash": "Trash: %@",
        "mon.cpu": "CPU", "mon.memory": "Memory", "mon.battery": "Battery",
        "mon.thermal": "Thermal", "mon.system": "System", "mon.disk": "Disk",
        "mon.loadAvg": "Load: %@ · %@ · %@",
        "mon.cores": "%d cores",
        "mon.usedOf": "%@ of %@",
        "mon.swap": "Swap: %@",
        "mon.charging": "charging", "mon.discharging": "on battery",
        "mon.noBattery": "No battery — running on AC power",
        "mon.thermal.nominal": "Nominal",
        "mon.thermal.fair": "Fair",
        "mon.thermal.serious": "High — your Mac is throttling",
        "mon.thermal.critical": "Critical!",
        "mon.tempNote": "Exact temperatures and fan speeds on Apple Silicon require administrator rights — so we show the system's own thermal pressure estimate instead.",
        "mon.uptime": "Uptime: %@",
        "mon.mac": "macOS %@ · %@",
        "mon.freeOf": "%@ free of %@",
        "mb.network": "Network",
        "mb.ip": "Local IP: %@",
        "mb.down": "↓ %@/s",
        "mb.up": "↑ %@/s",
        "mb.pubip": "Public IP: %@ %@",
        "mon.ram": "%@ RAM",
        "mb.offline": "Offline",
    ]
}

// MARK: - Базовые типы

struct CleanItem: Identifiable, Hashable {
    let id = UUID()
    var path: String
    var name: String
    var size: UInt64
    var mtime: Date?
    var isDir: Bool
    var note: String?
}

enum ScanStatus: Equatable {
    case idle
    case scanning
    case done
    case denied
    case error(String)
}

@Observable
final class CategoryState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let isSafe: Bool
    let isTrash: Bool

    var status: ScanStatus = .idle
    var items: [CleanItem] = []
    var expanded: Bool = false

    var total: UInt64 { items.reduce(0) { $0 + $1.size } }

    init(id: String, title: String, subtitle: String, icon: String, isSafe: Bool, isTrash: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSafe = isSafe
        self.isTrash = isTrash
    }
}

// MARK: - Обзор диска

enum FileCategory: String, CaseIterable, Identifiable, Codable {
    case video = "Видео"
    case images = "Образы и фото"
    case archives = "Архивы и образы"
    case docs = "Документы"
    case apps = "Приложения"
    case dev = "Разработка"
    case other = "Другое"

    var id: String { rawValue }

    /// Ключ локализации названия категории (video/images/archives/…)
    var titleKey: String {
        switch self {
        case .video: return "catname.video"
        case .images: return "catname.images"
        case .archives: return "catname.archives"
        case .docs: return "catname.docs"
        case .apps: return "catname.apps"
        case .dev: return "catname.dev"
        case .other: return "catname.other"
        }
    }

    var color: Color {
        switch self {
        case .video: return Color(red: 0.60, green: 0.55, blue: 0.97)   // фиолетовый
        case .images: return Color(red: 0.95, green: 0.65, blue: 0.78)  // розовый
        case .archives: return Color(red: 0.96, green: 0.72, blue: 0.45)// оранжевый
        case .docs: return Color(red: 0.55, green: 0.72, blue: 0.95)    // голубой
        case .apps: return Color(red: 0.42, green: 0.84, blue: 0.72)    // бирюзовый
        case .dev: return Color(red: 0.86, green: 0.89, blue: 0.45)     // лаймовый
        case .other: return Color(nsColor: .separatorColor)
        }
    }
}

struct LargeFile: Identifiable, Hashable, Codable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let access: Date?
    let category: FileCategory
    var isDir: Bool = false

    // id не сохраняем в кэш — при загрузке генерируется новый
    enum CodingKeys: String, CodingKey {
        case path, name, size, access, category, isDir
    }

    var accessNote: String {
        guard let access else { return "" }
        let months = Calendar.current.dateComponents([.month], from: access, to: Date()).month ?? 0
        if L10n.shared.lang == "en" {
            if months < 1 { return "opened recently" }
            if months < 12 { return "not opened for \(months) mo." }
            return "not opened for \(months / 12) yr."
        }
        if months < 1 { return "открывался недавно" }
        if months < 12 { return "не открывался \(months) мес." }
        let years = months / 12
        return "не открывался \(years) " + (years == 1 ? "год" : years < 5 ? "года" : "лет")
    }
}

@Observable
final class DiskScanState {
    enum Phase: Equatable {
        case idle
        case scanning
        case done
        case error(String)
    }
    var phase: Phase = .idle
    var filesScanned: Int = 0
    var currentPath: String = ""
    var byCategory: [FileCategory: UInt64] = [:]
    var largeFiles: [LargeFile] = []
    var dupeCandidates: [LargeFile] = []
    var topByCategory: [FileCategory: [LargeFile]] = [:]
    var topFolders: [LargeFile] = []
    /// Карта диска: размеры папок глубиной 1 от домашней
    var topLevel: [String: UInt64] = [:]
    /// Карта диска: размеры папок глубиной 2–3
    var folderSizes: [String: UInt64] = [:]
    var volumeTotal: UInt64 = 0
    var volumeFree: UInt64 = 0
    var finishedAt: Date?

    var usedByKnown: UInt64 { byCategory.values.reduce(0, +) }
}

// MARK: - Дубликаты

struct DupeGroup: Identifiable, Hashable {
    let id = UUID()
    let hash: String
    let size: UInt64
    var paths: [String]
    var waste: UInt64 { size * UInt64(paths.count - 1) }
}

@Observable
final class DupeScanState {
    var status: ScanStatus = .idle
    var groups: [DupeGroup] = []
    var totalWaste: UInt64 { groups.reduce(0) { $0 + $1.waste } }
}

// MARK: - Приложения

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let bundleID: String
    let size: UInt64
    var icon: NSImage? = nil
    /// Дата последнего запуска (Spotlight kMDItemLastUsedDate, fallback — access time)
    var lastUsed: Date? = nil

    func hash(into hasher: inout Hasher) { hasher.combine(url) }
    static func == (a: AppEntry, b: AppEntry) -> Bool { a.url == b.url }

    /// Сколько месяцев приложение не открывали (0 — открывали недавно или нет данных)
    var monthsUnused: Int {
        guard let lastUsed else { return 0 }
        return Calendar.current.dateComponents([.month], from: lastUsed, to: Date()).month ?? 0
    }

    /// «не открывалось N мес.» — подсказка в списке
    var lastUsedNote: String? {
        let months = monthsUnused
        guard months >= 1 else { return nil }
        if L10n.shared.lang == "en" {
            if months < 12 { return "not opened for \(months) mo." }
            return "not opened for \(months / 12) yr."
        }
        if months < 12 { return "не открывалось \(months) мес." }
        let years = months / 12
        return "не открывалось \(years) " + (years == 1 ? "год" : years < 5 ? "года" : "лет")
    }

    /// «Пыльное» приложение: полгода и больше без запуска
    var isStale: Bool { monthsUnused >= 6 }
}

@Observable
final class AppsState {
    var status: ScanStatus = .idle
    var apps: [AppEntry] = []
    var orphans: [CleanItem] = []
    var orphansScanned = false
    // Лист удаления конкретного приложения
    var pendingApp: AppEntry?
    var pendingLeftovers: [CleanItem] = []
    var showUninstallSheet = false
}

// MARK: - Автозагрузка

struct StartupItem: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let label: String
    let program: String
    let size: UInt64
    /// Программа, на которую ссылается агент, уже удалена
    var programMissing: Bool = false
}

@Observable
final class StartupState {
    var status: ScanStatus = .idle
    var items: [StartupItem] = []
}

// MARK: - Расширения системы

struct ExtensionGroup: Identifiable {
    var id: String { key }
    let key: String          // ключ локализации названия группы (ext.quicklook и т.п.)
    var items: [CleanItem]
    var total: UInt64 { items.reduce(0) { $0 + $1.size } }
}

@Observable
final class ExtensionsState {
    var status: ScanStatus = .idle
    var groups: [ExtensionGroup] = []

    var count: Int { groups.reduce(0) { $0 + $1.items.count } }
    var total: UInt64 { groups.reduce(0) { $0 + $1.total } }
}

// MARK: - История

struct HistoryEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let count: Int
    let bytes: UInt64
    let paths: [String]
}

// MARK: - Снапшоты состояния диска (график «свободно» и «Что выросло»)

/// Пишется после каждого успешного глубокого сканирования.
struct DiskSnapshot: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let free: UInt64
    let total: UInt64
    /// Размеры по категориям; ключ — rawValue FileCategory (стабилен, не зависит от языка)
    let byCategory: [String: UInt64]
}

/// Разница по категории между двумя последними снапшотами («Что выросло»)
struct CategoryGrowth: Identifiable {
    var id: String { category.rawValue }
    let category: FileCategory
    /// Положительная — категория выросла, отрицательная — уменьшилась
    let delta: Int64
}

// MARK: - Разделы сайдбара

enum AppSection: String, CaseIterable, Identifiable {
    case overview = "Обзор диска"
    case largeFiles = "Большие файлы"
    case folders = "Тяжёлые папки"
    case map = "Карта диска"
    case duplicates = "Дубликаты"
    case apps = "Приложения"
    case downloads = "Загрузки"
    case junk = "Системный мусор"
    case startup = "Автозагрузка"
    case extensions = "Расширения"
    case trash = "Корзина"
    case history = "История"
    case monitor = "Мониторинг"
    case settings = "Настройки"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .largeFiles: return "doc"
        case .folders: return "folder.fill"
        case .map: return "square.split.2x2"
        case .duplicates: return "square.on.square"
        case .apps: return "square.grid.2x2"
        case .downloads: return "arrow.down.circle"
        case .junk: return "archivebox"
        case .startup: return "bolt"
        case .extensions: return "puzzlepiece.extension"
        case .trash: return "trash"
        case .history: return "clock.arrow.circlepath"
        case .monitor: return "cpu"
        case .settings: return "gearshape"
        }
    }

    /// Ключ локализации названия раздела
    var titleKey: String {
        switch self {
        case .overview: return "sec.overview"
        case .largeFiles: return "sec.largeFiles"
        case .folders: return "sec.folders"
        case .map: return "sec.map"
        case .duplicates: return "sec.duplicates"
        case .apps: return "sec.apps"
        case .downloads: return "sec.downloads"
        case .junk: return "sec.junk"
        case .startup: return "sec.startup"
        case .extensions: return "sec.extensions"
        case .trash: return "sec.trash"
        case .history: return "sec.history"
        case .monitor: return "sec.monitor"
        case .settings: return "sec.settings"
        }
    }

    /// Горячая клавиша раздела (нажимается с ⌘): 1…9 по порядку в сайдбаре,
    /// 0 — Корзина, запятая — Настройки (стандарт macOS).
    /// У Расширений, Истории и Мониторинга нет — цифры кончились.
    var shortcutKey: KeyEquivalent? {
        switch self {
        case .overview: return "1"
        case .largeFiles: return "2"
        case .folders: return "3"
        case .map: return "4"
        case .duplicates: return "5"
        case .apps: return "6"
        case .downloads: return "7"
        case .junk: return "8"
        case .startup: return "9"
        case .trash: return "0"
        case .settings: return ","
        case .extensions, .monitor, .history: return nil
        }
    }

    /// Подсказка для тултипа в сайдбаре: «⌘1»
    var shortcutHint: String? {
        guard let key = shortcutKey else { return nil }
        return "⌘\(key.character)"
    }
}

// MARK: - Главная модель

@MainActor
@Observable
final class CleanerViewModel {
    /// Доступ из App Intents (Shortcuts) к запущенной модели
    static weak var shared: CleanerViewModel?

    init() {
        CleanerViewModel.shared = self
    }

    var section: AppSection = .overview
    /// Счётчик запросов фокуса на поле поиска (Cmd+F): поле следит и берёт фокус
    var searchFocusRequest: Int = 0
    /// Открытая категория детализации в «Обзоре диска» (nil — обычный обзор)
    var drillCategory: FileCategory? = nil

    /// Тема оформления: "system" | "light" | "dark" (хранится в UserDefaults)
    var theme: String = UserDefaults.standard.string(forKey: "appTheme") ?? "system" {
        didSet {
            UserDefaults.standard.set(theme, forKey: "appTheme")
            applyTheme()
        }
    }

    /// Тема через AppKit: appearance = nil надёжно следует за системой и
    /// обновляется живьём, в отличие от preferredColorScheme(nil)
    func applyTheme() {
        switch theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }

    /// Иконка со свободным местом в меню-баре (по умолчанию включена)
    var menuBarEnabled: Bool = UserDefaults.standard.object(forKey: "menuBarEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(menuBarEnabled, forKey: "menuBarEnabled")
            MenuBarController.shared.apply(enabled: menuBarEnabled)
        }
    }

    /// Стиль анимированной иконки меню-бара
    var menuBarIconStyle: MenuBarIconStyle =
        MenuBarIconStyle(rawValue: UserDefaults.standard.string(forKey: "menuBarIconStyle") ?? "trash") ?? .trash {
        didSet {
            UserDefaults.standard.set(menuBarIconStyle.rawValue, forKey: "menuBarIconStyle")
            MenuBarController.shared.iconStyle = menuBarIconStyle
        }
    }

    /// Иконка приложения в Dock (по умолчанию включена).
    /// Выключается — приложение становится фоновым агентом (.accessory):
    /// висит без иконки в Dock, управление через меню-бар.
    /// Чтобы приложение не потерялось, меню-бар при этом включаем принудительно.
    var showDockIcon: Bool = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
            if !showDockIcon && !menuBarEnabled {
                menuBarEnabled = true
            }
            applyDockPolicy()
        }
    }

    /// Применяет режим видимости в Dock (зовётся из didSet и при запуске)
    func applyDockPolicy() {
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
        if !showDockIcon {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// nil = как в системе (preferredColorScheme(nil) следует за macOS)
    var colorScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // Системный мусор (категории из первой версии)
    var categories: [CategoryState] = [
        CategoryState(id: "caches", title: "Кэши приложений",
                      subtitle: "~/Library/Caches — приложения создадут заново",
                      icon: "archivebox", isSafe: false),
        CategoryState(id: "logs", title: "Логи",
                      subtitle: "Журналы из ~/Library/Logs",
                      icon: "doc.text", isSafe: false),
        CategoryState(id: "xcode", title: "Xcode и симуляторы",
                      subtitle: "DerivedData и кэши — пересоздаются при сборке",
                      icon: "hammer", isSafe: false),
        CategoryState(id: "pkgman", title: "Кэши пакетных менеджеров",
                      subtitle: "npm, pip, bun, yarn, Homebrew, Gradle",
                      icon: "shippingbox", isSafe: false),
        CategoryState(id: "node_modules", title: "node_modules в проектах",
                      subtitle: "Восстанавливаются командой npm install",
                      icon: "cube", isSafe: false),
        CategoryState(id: "mobilesync", title: "Бэкапы iPhone и iPad",
                      subtitle: "Старые бэкапы устройств из MobileSync — проверь, какие ещё нужны",
                      icon: "iphone", isSafe: false),
        CategoryState(id: "mail", title: "Вложения почты",
                      subtitle: "Копии открытых вложений — оригиналы остаются в письмах",
                      icon: "envelope", isSafe: false),
        CategoryState(id: "projjunk", title: "Сборки проектов",
                      subtitle: "dist, .next, target, build, Pods, venv — пересоздаются при сборке",
                      icon: "hammer.circle", isSafe: false),
        CategoryState(id: "docker", title: "Docker",
                      subtitle: "Виртуальный диск и кэши Docker Desktop",
                      icon: "shippingbox.circle", isSafe: false),
        CategoryState(id: "crashlogs", title: "Крашлоги",
                      subtitle: "Отчёты о сбоях приложений из DiagnosticReports",
                      icon: "ladybug", isSafe: false),
        CategoryState(id: "partial", title: "Недокачки и виндовый мусор",
                      subtitle: ".download, .crdownload, .part, Thumbs.db, desktop.ini",
                      icon: "arrow.down.doc", isSafe: false),
        CategoryState(id: "plist", title: "Битые настройки",
                      subtitle: "Повреждённые .plist — приложение создаст новые",
                      icon: "gearshape.2", isSafe: false),
        CategoryState(id: "privacy", title: "Приватность браузеров",
                      subtitle: "История и куки — закройте браузер перед удалением",
                      icon: "hand.raised", isSafe: false),
    ]

    var downloadsCategory = CategoryState(id: "downloads", title: "Старые загрузки (> 30 дней)",
                                          subtitle: "Файлы из ~/Downloads, которым больше месяца",
                                          icon: "arrow.down.circle", isSafe: false)
    var trashCategory = CategoryState(id: "trash", title: "Корзина",
                                      subtitle: "Очистка необратима",
                                      icon: "trash", isSafe: false, isTrash: true)

    var disk = DiskScanState()
    var dupes = DupeScanState()
    var appsState = AppsState()
    var startup = StartupState()
    var extensionsState = ExtensionsState()
    var monitor = MonitorState()
    var history: [HistoryEntry] = []
    /// Снапшоты диска по итогам сканирований (старые — первые)
    var snapshots: [DiskSnapshot] = []

    /// «Что выросло»: разница категорий между двумя последними снапшотами,
    /// отсортирована по модулю изменения (самые заметные — первые)
    var growth: [CategoryGrowth] {
        guard snapshots.count >= 2 else { return [] }
        let last = snapshots[snapshots.count - 1]
        let prev = snapshots[snapshots.count - 2]
        return FileCategory.allCases.compactMap { cat in
            let d = Int64(last.byCategory[cat.rawValue] ?? 0)
                  - Int64(prev.byCategory[cat.rawValue] ?? 0)
            return d == 0 ? nil : CategoryGrowth(category: cat, delta: d)
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    var selected: Set<String> = []
    var sizeIndex: [String: UInt64] = [:]   // path → size, для подсчёта выбранного

    var freedSession: UInt64 = 0
    var showTrashConfirm = false
    var showEmptyTrashConfirm = false
    var toast: String?

    var selectedSize: UInt64 { selected.reduce(0) { $0 + (sizeIndex[$1] ?? 0) } }

    // MARK: Индексация и выбор

    func index(_ items: [CleanItem]) {
        for i in items { sizeIndex[i.path] = i.size }
    }
    func index(_ files: [LargeFile]) {
        for f in files { sizeIndex[f.path] = f.size }
    }
    func toggle(_ path: String, _ on: Bool) {
        if on { selected.insert(path) } else { selected.remove(path) }
    }

    // MARK: Сканирование категорий мусора

    func scanAllJunk() async {
        await withTaskGroup(of: Void.self) { group in
            for cat in categories + [downloadsCategory, trashCategory] {
                group.addTask { await self.scanJunk(cat) }
            }
        }
    }

    func scanJunk(_ cat: CategoryState) async {
        for item in cat.items { selected.remove(item.path); sizeIndex.removeValue(forKey: item.path) }
        cat.status = .scanning
        cat.items = []
        cat.expanded = false
        do {
            let result = try await Scanner.scan(id: cat.id)
            cat.items = result.items
            cat.status = result.denied ? .denied : .done
            index(result.items)
            if cat.isSafe {
                for item in result.items { selected.insert(item.path) }
            }
        } catch {
            cat.status = .error(error.localizedDescription)
        }
    }

    // MARK: Глубокое сканирование диска

    /// Лёгкое обновление цифр «свободно/всего» без перебора файлов —
    /// не требует разрешений, можно звать при запуске приложения
    func refreshVolumeInfo() {
        let caps = Scanner.volumeCapacities()
        disk.volumeTotal = caps.total
        disk.volumeFree = caps.free
    }

    /// Полное сканирование по кнопке + тихие сканы для «Что дальше?»
    func scanWithRecommendations(force: Bool, cancel: Scanner.CancelFlag? = nil) async {
        await runDeepScan(force: force, cancel: cancel)
        if disk.phase == .done {
            if downloadsCategory.status == .idle { await scanJunk(downloadsCategory) }
            if trashCategory.status == .idle { await scanJunk(trashCategory) }
        }
    }

    /// Сканирование как отменяемая задача — кнопка «Отмена» в карточке прогресса
    private var deepScanTask: Task<Void, Never>?
    private var deepScanCancel: Scanner.CancelFlag?

    func startDeepScan(force: Bool = false) {
        deepScanTask?.cancel()
        let flag = Scanner.CancelFlag()
        deepScanCancel = flag
        deepScanTask = Task { await scanWithRecommendations(force: force, cancel: flag) }
    }

    func cancelDeepScan() {
        deepScanCancel?.cancel()   // для detached-обхода внутри Scanner
        deepScanTask?.cancel()     // для всего остального
        deepScanTask = nil
    }

    func runDeepScan(force: Bool = false, cancel: Scanner.CancelFlag? = nil) async {
        if disk.phase == .scanning { return }
        if disk.phase == .done && !force { return }
        disk.phase = .scanning
        disk.filesScanned = 0
        disk.byCategory = [:]
        disk.largeFiles = []
        disk.dupeCandidates = []
        let caps = Scanner.volumeCapacities()
        disk.volumeTotal = caps.total
        disk.volumeFree = caps.free
        do {
            let result = try await Scanner.deepScan(cancel: cancel) { [weak self] count, path in
                Task { @MainActor in
                    self?.disk.filesScanned = count
                    self?.disk.currentPath = path
                }
            }
            disk.byCategory = result.byCategory
            disk.largeFiles = result.large
            disk.dupeCandidates = result.dupeCandidates
            disk.topByCategory = result.topByCategory
            disk.topFolders = result.topFolders
            disk.topLevel = result.topLevel
            disk.folderSizes = result.folderSizes
            disk.finishedAt = Date()
            disk.phase = .done
            appendSnapshot()
            index(result.large)
            index(result.dupeCandidates)
            index(result.topFolders)
            for files in result.topByCategory.values { index(files) }
            saveScanCache(result)
        } catch is CancellationError {
            // Пользователь нажал «Отмена» — просто возвращаемся в исходное состояние
            disk.phase = .idle
        } catch {
            disk.phase = .error(error.localizedDescription)
        }
    }

    // MARK: Кэш последнего сканирования

    /// Результат глубокого сканирования + дата, JSON на диске.
    /// После перезапуска приложения разделы открываются сразу со старыми данными
    /// (с пометкой «обновлено …»), пересканирование — только по кнопке.
    private struct ScanCache: Codable {
        var finishedAt: Date
        var result: DeepScanResult
    }

    private var scanCacheURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacCleaner", isDirectory: true)
            .appendingPathComponent("scan-cache.json")
    }

    private func saveScanCache(_ result: DeepScanResult) {
        let cache = ScanCache(finishedAt: Date(), result: result)
        let url = scanCacheURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Поднять кэш при запуске. Только если сканирование ещё не запускали.
    func loadScanCache() {
        guard disk.phase == .idle,
              let data = try? Data(contentsOf: scanCacheURL),
              let cache = try? JSONDecoder().decode(ScanCache.self, from: data)
        else { return }
        let r = cache.result
        disk.byCategory = r.byCategory
        disk.largeFiles = r.large
        disk.dupeCandidates = r.dupeCandidates
        disk.topByCategory = r.topByCategory
        disk.topFolders = r.topFolders
        disk.topLevel = r.topLevel
        disk.folderSizes = r.folderSizes
        disk.finishedAt = cache.finishedAt
        disk.phase = .done
        index(r.large)
        index(r.dupeCandidates)
        index(r.topFolders)
        for files in r.topByCategory.values { index(files) }
    }

    // MARK: Дубликаты

    func runDupeScan() async {
        if dupes.status == .scanning { return }
        dupes.status = .scanning
        // Дождаться завершения идущего сканирования диска
        while disk.phase == .scanning {
            try? await Task.sleep(for: .milliseconds(500))
        }
        if disk.phase != .done { await runDeepScan() }
        guard disk.phase == .done else {
            dupes.status = .idle
            return
        }
        let groups = await Scanner.findDuplicates(in: disk.dupeCandidates)
        dupes.groups = groups
        dupes.status = .done
    }

    // MARK: Приложения

    func scanApps() async {
        if appsState.status == .scanning { return }
        appsState.status = .scanning
        appsState.apps = await Scanner.scanApps()
        appsState.orphans = await Scanner.findOrphans(installedApps: appsState.apps)
        appsState.orphansScanned = true
        index(appsState.orphans)
        appsState.status = .done
    }

    func prepareUninstall(_ app: AppEntry) async {
        appsState.pendingLeftovers = await Scanner.findLeftovers(of: app)
        appsState.pendingApp = app
        appsState.showUninstallSheet = true
    }

    // MARK: Снимки Time Machine (только информация)

    /// nil — ещё не загружали; (кол-во, дата последнего)
    var tmSnapshots: (count: Int, last: String?)? = nil

    func loadTMSnapshots() async {
        tmSnapshots = await Scanner.tmSnapshots()
    }

    // MARK: Автозагрузка

    func scanStartup() async {
        startup.status = .scanning
        startup.items = await Scanner.scanLaunchAgents()
        for i in startup.items { sizeIndex[i.path] = i.size }
        startup.status = .done
    }

    // MARK: Расширения системы

    func scanExtensions() async {
        extensionsState.status = .scanning
        extensionsState.groups = await Scanner.scanExtensions()
        for g in extensionsState.groups { index(g.items) }
        extensionsState.status = .done
    }

    // MARK: Удаление (только через Корзину)

    func trashSelected() async {
        let paths = selected
        var freed: UInt64 = 0
        var failed = 0
        var moved: Set<String> = []
        for path in paths {
            do {
                var resulting: NSURL?
                try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: &resulting)
                moved.insert(path)
                freed += sizeIndex[path] ?? 0
            } catch {
                failed += 1
            }
        }
        removeFromAllLists(moved)
        selected.subtract(moved)
        freedSession += freed
        if !moved.isEmpty {
            appendHistory(count: moved.count, bytes: freed, paths: Array(moved))
        }
        if failed > 0 {
            showToast(L10n.shared.f("toast.partial", moved.count, failed))
        } else {
            showToast(L10n.shared.f("toast.freed", Format.bytes(freed)))
        }
    }

    func trashPaths(_ paths: [String]) async {
        for p in paths { selected.insert(p) }
        await trashSelected()
    }

    private func removeFromAllLists(_ moved: Set<String>) {
        for p in moved { sizeIndex.removeValue(forKey: p) }
        for cat in categories { cat.items.removeAll { moved.contains($0.path) } }
        downloadsCategory.items.removeAll { moved.contains($0.path) }
        trashCategory.items.removeAll { moved.contains($0.path) }
        disk.largeFiles.removeAll { moved.contains($0.path) }
        disk.dupeCandidates.removeAll { moved.contains($0.path) }
        disk.topFolders.removeAll { moved.contains($0.path) }
        for cat in disk.topByCategory.keys {
            disk.topByCategory[cat]?.removeAll { moved.contains($0.path) }
        }
        appsState.orphans.removeAll { moved.contains($0.path) }
        appsState.apps.removeAll { moved.contains($0.url.path) }
        startup.items.removeAll { moved.contains($0.path) }
        for gi in extensionsState.groups.indices {
            extensionsState.groups[gi].items.removeAll { moved.contains($0.path) }
        }
        extensionsState.groups.removeAll { $0.items.isEmpty }
        for i in dupes.groups.indices {
            dupes.groups[i].paths.removeAll { moved.contains($0) }
        }
        dupes.groups.removeAll { $0.paths.count < 2 }
    }

    // MARK: Корзина

    func emptyTrash() async {
        let ok = await Scanner.emptyTrashViaFinder()
        showToast(L10n.shared.t(ok ? "toast.trashEmptied" : "toast.trashFail"))
        await scanJunk(trashCategory)
    }

    // MARK: История

    private var historyURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MacCleaner")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        history = (try? dec.decode([HistoryEntry].self, from: data)) ?? []
        loadSnapshots()
    }

    private func appendHistory(count: Int, bytes: UInt64, paths: [String]) {
        history.insert(HistoryEntry(date: Date(), count: count, bytes: bytes, paths: paths), at: 0)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(history) {
            try? data.write(to: historyURL)
        }
    }

    // MARK: Снапшоты диска

    private var snapshotsURL: URL {
        historyURL.deletingLastPathComponent().appendingPathComponent("snapshots.json")
    }

    /// Снапшот после успешного сканирования. Если прошлый младше 5 минут —
    /// заменяем его, чтобы случайный двойной скан подряд не засорял график.
    private func appendSnapshot() {
        var cats: [String: UInt64] = [:]
        for (cat, bytes) in disk.byCategory { cats[cat.rawValue] = bytes }
        let snap = DiskSnapshot(date: Date(), free: disk.volumeFree,
                                total: disk.volumeTotal, byCategory: cats)
        if let last = snapshots.last,
           Date().timeIntervalSince(last.date) < 5 * 60 {
            snapshots[snapshots.count - 1] = snap
        } else {
            snapshots.append(snap)
        }
        if snapshots.count > 200 {
            snapshots.removeFirst(snapshots.count - 200)
        }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(snapshots) {
            try? data.write(to: snapshotsURL)
        }
    }

    private func loadSnapshots() {
        guard let data = try? Data(contentsOf: snapshotsURL) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        snapshots = (try? dec.decode([DiskSnapshot].self, from: data)) ?? []
    }

    // MARK: Тост

    func showToast(_ text: String) {
        toast = text
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            await MainActor.run { self?.toast = nil }
        }
    }
}

// MARK: - Форматирование

enum Format {
    static func bytes(_ value: UInt64) -> String {
        if value == 0 { return "0 Б" }
        return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }
    /// Для оперативной памяти — 1024-базовые единицы:
    /// 24 ГиБ показываются как «24 ГБ», а не «25,77 GB»
    static func memory(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
    }
    /// Со знаком: «+1,2 ГБ» / «−300 МБ» (для «Что выросло»)
    static func signedBytes(_ value: Int64) -> String {
        if value == 0 { return "0" }
        let absStr = ByteCountFormatter.string(fromByteCount: abs(value), countStyle: .file)
        return (value > 0 ? "+" : "−") + absStr
    }
    static func date(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(date: .numeric, time: .omitted)
    }
    static func dateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
