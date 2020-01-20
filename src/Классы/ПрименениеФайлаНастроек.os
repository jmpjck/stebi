#Использовать logos
#Использовать v8metadata-reader

Перем _Лог;

Перем _ПрименятьНастройки;
Перем _ФайлыОшибок;
Перем _ФайлНастроек;
Перем _КаталогИсходников;
Перем _ФайлыСИсходнымКодом;

Перем _КешПравил;

Перем _УдалятьПоддержку;
Перем _ДанныеПоддержки;

Перем _ФильтрПоПодсистемам;
Перем _ДанныеФильтраПоПодсистемам;

Перем ВАЖНОСТЬ_ПРОПУСТИТЬ;
Перем ДОСТУПНЫЕ_ВАЖНОСТИ;
Перем ДОСТУПНЫЕ_ТИПЫ;

#Область ПрограммныйИнтерфейс

Процедура ОписаниеКоманды(Команда) Экспорт
	
	Команда.Аргумент(
		"GENERIC_ISSUE_JSON",
		"",
		"Путь к файлам generic-issue.json, на основе которых будет создан файл настроек. Например ./edt-json.json,./acc-generic-issue.json")
	.ТСтрока()
	.ВОкружении("GENERIC_ISSUE_JSON");
	
	Команда.Опция("s settings", "", "Путь к файлу настроек. Например -s=./generic-issue-settings.json")
	.ТСтрока()
	.ВОкружении("GENERIC_ISSUE_SETTINGS_JSON");
	
	Команда.Опция("src", "", "Путь к каталогу с исходниками. Например -src=./src")
	.ТСтрока()
	.ВОкружении("SRC");
	
	Команда.Опция("r remove_support", "", "Удаляет из отчетов файлы на поддержке. Например -r=0
		|		0 - удалить файлы на замке,
		|		1 - удалить файлы на замке и на поддержке
		|		2 - удалить файлы на замке, на поддержке и снятые с поддержки")
	.ТЧисло()
	.ВОкружении("GENERIC_ISSUE_REMOVE_SUPPORT");
	
	Команда.Опция("f filter_by_subsystem", "", "Фильтр по подсистеме в формате [+/-]Подсистема1.Подсистема2[*][^].
		|		Например, исключение подсистем СтандартныеПодсистемы и ПодключаемоеОборудование и всех дочерних объектов
		|			'-СтандартныеПодсистемы*, -ПодключаемоеОборудование*'")
	.ТСтрока()
	.ВОкружении("GENERIC_ISSUE_FILTER_BY_SUBSYSTEM");
	
КонецПроцедуры

Процедура ВыполнитьКоманду(Знач Команда) Экспорт
	
	ВАЖНОСТЬ_ПРОПУСТИТЬ = "SKIP";
	ДОСТУПНЫЕ_ВАЖНОСТИ = Новый Массив;
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("BLOCKER");
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("CRITICAL");
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("MAJOR");
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("MINOR");
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("INFO");
	ДОСТУПНЫЕ_ВАЖНОСТИ.Добавить("SKIP");
	
	ДОСТУПНЫЕ_ТИПЫ = Новый Массив;
	ДОСТУПНЫЕ_ТИПЫ.Добавить("BUG");
	ДОСТУПНЫЕ_ТИПЫ.Добавить("VULNERABILITY");
	ДОСТУПНЫЕ_ТИПЫ.Добавить("CODE_SMELL");
	
	началоОбщегоЗамера = ТекущаяДата();
	
	ИнициализацияПараметров(Команда);
	
	таблицаНастроек = ТаблицаНастроек();
	
	Для каждого цФайл Из _файлыОшибок Цикл
		
		замечанияФайла = ПрочитатьЗамечанияИзФайла(цФайл);
		
		началоЗамера = ТекущаяУниверсальнаяДатаВМиллисекундах();
		
		файлИзменен = Ложь;
		
		всегоЗамечаний = замечанияФайла.issues.Количество();
		
		Для ц = 1 По всегоЗамечаний Цикл
			
			цЗамечание = замечанияФайла.issues[всегоЗамечаний - ц];
			
			Если ОшибкаВЗамечании(цЗамечание)
				ИЛИ ФайлНаПоддержке(цЗамечание)
				ИЛИ ИсключитьЗамечаниеФильтромПоПодсистеме(цЗамечание) Тогда
				
				замечанияФайла.issues.Удалить(всегоЗамечаний - ц);
				файлИзменен = Истина;
				Продолжить;
				
			КонецЕсли;

			Если ПрименитьНастройки(цЗамечание, таблицаНастроек) Тогда
				
				файлИзменен = Истина;
				
			КонецЕсли;
			
			Если цЗамечание.severity = ВАЖНОСТЬ_ПРОПУСТИТЬ Тогда
				
				замечанияФайла.issues.Удалить(всегоЗамечаний - ц);
				файлИзменен = Истина;
				Продолжить;
				
			КонецЕсли;
			
		КонецЦикла;
		
		_Лог.Информация("Файл <%1> обработан за %2мс", цФайл, ТекущаяУниверсальнаяДатаВМиллисекундах() - началоЗамера);
		
		ЗаписатьОшибкиВФайл(замечанияФайла, цФайл, файлИзменен);
		
	КонецЦикла;
	
	_Лог.Информация("Общее время обработки: %1с", ТекущаяДата() - началоОбщегоЗамера);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

Функция ИмяЛога() Экспорт
	
	Возврат "oscript.app." + ОПриложении.Имя();
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ИнициализацияПараметров(Знач Команда)
	
	_Лог = Логирование.ПолучитьЛог(ИмяЛога());
	
	файлыОшибок = Команда.ЗначениеАргумента("GENERIC_ISSUE_JSON");
	_лог.Информация("GENERIC_ISSUE_JSON = " + файлыОшибок);
	
	путьКФайлуНастроек = Команда.ЗначениеОпции("settings");
	_лог.Информация("settings = " + путьКФайлуНастроек);
	
	путьККаталогуИсходников = Команда.ЗначениеОпции("src");
	_лог.Информация("src = " + путьККаталогуИсходников);
	
	_УдалятьПоддержку = Команда.ЗначениеОпции("remove_support");
	_лог.Информация("remove_support = " + _УдалятьПоддержку);
	
	_ФильтрПоПодсистемам = Команда.ЗначениеОпции("filter_by_subsystem");
	_лог.Информация("filter_by_subsystem = " + _ФильтрПоПодсистемам);
	
	Если ЗначениеЗаполнено(путьКФайлуНастроек) Тогда
		
		_ФайлНастроек = ОбщегоНазначения.АбсолютныйПуть(путьКФайлуНастроек);
		_лог.Информация("Файл настроек = " + _ФайлНастроек);
		
		_ПрименятьНастройки = ОбщегоНазначения.ФайлСуществует(_ФайлНастроек);
		
	Иначе
		
		_ПрименятьНастройки = Ложь;
		
	КонецЕсли;
	
	_файлыОшибок = Новый Массив;
	
	Для каждого цПутьКФайлу Из СтрРазделить(файлыОшибок, ",") Цикл
		
		Если ОбщегоНазначения.ФайлСуществует(цПутьКФайлу) Тогда
			
			файлСОшибками = ОбщегоНазначения.АбсолютныйПуть(цПутьКФайлу);
			
			_файлыОшибок.Добавить(файлСОшибками);
			
			_лог.Отладка("Добавлен файл generic-issue = " + файлСОшибками);
			
		КонецЕсли;
		
	КонецЦикла;
	
	_КаталогИсходников = ОбщегоНазначения.АбсолютныйПуть(путьККаталогуИсходников);
	каталогИсходников = Новый Файл(_КаталогИсходников);
	_лог.Информация("Каталог исходников = " + _КаталогИсходников);
	
	Если Не каталогИсходников.Существует()
		Или Не каталогИсходников.ЭтоКаталог() Тогда
		
		_лог.Ошибка(СтрШаблон("Каталог исходников <%1> не существует. Файлы на поддержке удалены не будут", путьККаталогуИсходников));
		_УдалятьПоддержку = Неопределено;
		
	КонецЕсли;
	
	Если Не _ПрименятьНастройки
		И _УдалятьПоддержку = Неопределено Тогда
		_Лог.Ошибка("Должен быть указан файл настроек или уровень удаления поддержки.");
		ЗавершитьРаботу(1);
	КонецЕсли;
	
	Если Не _УдалятьПоддержку = Неопределено Тогда
		
		_ДанныеПоддержки = Новый Поддержка(_КаталогИсходников);
		
	КонецЕсли;
	
	_ФайлыСИсходнымКодом = Новый Соответствие;
	
	ПодготовитьФильтрПоПодсистемам();
	
КонецПроцедуры

Функция ТаблицаНастроек()
	
	Если _ПрименятьНастройки Тогда
		
		_лог.Информация("Начало чтения файла настроек <%1>", _ФайлНастроек);
		таблицаНастроек = ОбщегоНазначения.ПолучитьТаблицуНастроек(_ФайлНастроек, _Лог);
		_лог.Информация("Из файла настроек прочитано: " + таблицаНастроек.Количество());
		
	Иначе
		
		таблицаНастроек = Новый ТаблицаЗначений;
		
	КонецЕсли;
	
	Возврат таблицаНастроек;
	
КонецФункции

Функция ПрочитатьЗамечанияИзФайла(Знач пФайл)
	
	замечанияФайла = ОбщегоНазначения.ПрочитатьJSONФайл(пФайл, _Лог);
	
	Если Не ТипЗнч(замечанияФайла) = Тип("Структура") Тогда
		
		_Лог.Ошибка("Не поддерживаемая структура файла: " + пФайл);
		Возврат Новый Массив;
		
	КонецЕсли;
	
	Если Не замечанияФайла.Свойство("issues") Тогда
		
		_Лог.Ошибка("Не поддерживаемая структура файла: " + пФайл);
		Возврат Новый Массив;
		
	КонецЕсли;
	
	Если Не ТипЗнч(замечанияФайла.issues) = Тип("Массив") Тогда
		
		_Лог.Ошибка("Не поддерживаемая структура файла: " + пФайл);
		Возврат Новый Массив;
		
	КонецЕсли;
	
	Возврат замечанияФайла;
	
КонецФункции

Процедура ЗаписатьОшибкиВФайл(Знач пзамечанияФайла, Знач пФайл, пФайлИзменен)
	
	Если пФайлИзменен Тогда
		
		_лог.Информация("Бекап файла: " + пФайл + ".old");
		КопироватьФайл(пФайл, пФайл + ".old");
		
		_лог.Информация("Запись в файл: " + пФайл);
		ОбщегоНазначения.ЗаписатьJSONВФайл(пзамечанияФайла, пФайл, _Лог);
		
	Иначе
		
		_лог.Информация("Изменения в файле не требуются: " + пФайл);
		
	КонецЕсли;
	
КонецПроцедуры

Функция ПрименитьНастройки(пОшибка, таблицаНастроек)
	
	естьИзменения = Ложь;
	
	ruleId = пОшибка.ruleId;
	message = пОшибка.primaryLocation.message;
	
	filePath = ПутьКФайлуСЗамечаниями(пОшибка, естьИзменения);
	
	Для каждого цСтрока Из таблицаНастроек Цикл
		
		Если пОшибка.severity = ВАЖНОСТЬ_ПРОПУСТИТЬ Тогда
			// Пропуск работает по принципу - применяем первое попавшееся,
			// когда как остальные настройки - последнее попавшееся.
			Прервать;
		КонецЕсли;
		
		Если НастройкаПрименима(ruleId, цСтрока.ruleId)
			И НастройкаПрименима(message, цСтрока.message)
			И НастройкаПрименима(filePath, цСтрока.filePath) Тогда
			
			Если ПрименитьНастройку(цСтрока, пОшибка) Тогда
				естьИзменения = Истина;
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат естьИзменения;
	
КонецФункции

Функция ПрименитьНастройку(Знач пСтрокаНастроек, пОшибка)

	естьИзменения = Ложь;
	заголовокЛога = СтрШаблон("ruleId: <%1>, message: <%2>, filePath: <%3>. Установлено ",
			пОшибка.ruleId,
			пОшибка.primaryLocation.message,
			пОшибка.primaryLocation.filePath);

	Если ТипЗнч(пСтрокаНастроек.effortMinutes) = Тип("Число")
		И Не пСтрокаНастроек.effortMinutes = пОшибка.effortMinutes Тогда
		
		_лог.Отладка(заголовокЛога + "effortMinutes: " + пСтрокаНастроек.effortMinutes);
		
		пОшибка.effortMinutes = пСтрокаНастроек.effortMinutes;
		естьИзменения = Истина;
		
	КонецЕсли;
	
	Если Не пСтрокаНастроек.severity = пОшибка.severity
		И Не ДОСТУПНЫЕ_ВАЖНОСТИ.Найти(пСтрокаНастроек.severity) = Неопределено Тогда
		
		_лог.Отладка(заголовокЛога + "severity: " + пСтрокаНастроек.severity);
		
		пОшибка.severity = пСтрокаНастроек.severity;
		естьИзменения = Истина;
		
	КонецЕсли;
	
	Если Не пСтрокаНастроек.type = пОшибка.type
		И Не ДОСТУПНЫЕ_ТИПЫ.Найти(пСтрокаНастроек.type) = Неопределено Тогда
		
		_лог.Отладка(заголовокЛога + "type: " + пСтрокаНастроек.type);
		
		пОшибка.type = пСтрокаНастроек.type;
		естьИзменения = Истина;
		
	КонецЕсли;

	Возврат естьИзменения;
	
КонецФункции

Функция ПутьКФайлуСЗамечаниями(пОшибка, пЕстьИзменения)
	
	путьКФайлуСЗамечанием = пОшибка.primaryLocation.filePath;

	filePath = ОбеспечитьПутьКФайлуСИсходнымКодом(путьКФайлуСЗамечанием);
	
	Если Не filePath = путьКФайлуСЗамечанием Тогда
		
		пЕстьИзменения = Истина;
		пОшибка.primaryLocation.filePath = filePath;
		
		Для каждого цВспомогательнаяСтрока Из пОшибка.secondaryLocations Цикл
			
			цВспомогательнаяСтрока.filePath = ОбеспечитьПутьКФайлуСИсходнымКодом(цВспомогательнаяСтрока.filePath);
			
		КонецЦикла;
		
	КонецЕсли;
	
	Возврат filePath;
	
КонецФункции

Функция НастройкаПрименима(Знач пСтрока, Знач пШаблон)
	
	Если пСтрока = пШаблон Тогда
		Возврат Истина;
	КонецЕсли;
	
	Если Не ЗначениеЗаполнено(пШаблон) Тогда
		Возврат Истина;
	КонецЕсли;
	
	значениеИзКеша = ПолучитьИзКеша(пСтрока, пШаблон);
	
	Если Не значениеИзКеша = Неопределено Тогда
		
		Возврат значениеИзКеша;
		
	КонецЕсли;
	
	этоПоискПоРегВыр = СтрНайти(пШаблон, "*") > 0; // Для оптимизации считаем, что если и используются рег. выражения, то со звездой
	
	Если этоПоискПоРегВыр Тогда
		
		Попытка
			
			регВыражение = Новый РегулярноеВыражение(пШаблон);
			настройкаПрименима = регВыражение.Совпадает(пСтрока);
			
		Исключение
			
			_Лог.Ошибка("Ошибка сравнения ""%1"" с рег. выражением ""%2""", пСтрока, пШаблон);
			_Лог.Ошибка(ОписаниеОшибки());
			настройкаПрименима = Ложь;
			
		КонецПопытки;
		
	Иначе
		
		настройкаПрименима = Ложь;
		
	КонецЕсли;
	
	ПоместитьВКеш(пСтрока, пШаблон, настройкаПрименима);
	
	Возврат настройкаПрименима;
	
КонецФункции

#Область Кеш

Функция ПолучитьИзКеша(Знач пСтрока, Знач пШаблон)
	
	ИнициализироватьКеш(пСтрока, пШаблон);
	
	Возврат _КешПравил[пШаблон][пСтрока];
	
КонецФункции

Процедура ПоместитьВКеш(Знач пСтрока, Знач пШаблон, Знач пЗначение)
	
	ИнициализироватьКеш(пСтрока, пШаблон);
	
	_КешПравил[пШаблон].Вставить(пСтрока, пЗначение);
	
КонецПроцедуры

Процедура ИнициализироватьКеш(Знач пСтрока, Знач пШаблон)
	
	Если _КешПравил = Неопределено Тогда
		
		_КешПравил = Новый Соответствие;
		
	КонецЕсли;
	
	КешПоШаблону = _КешПравил[пШаблон];
	
	Если КешПоШаблону = Неопределено Тогда
		
		КешПоШаблону = Новый Соответствие;
		_КешПравил.Вставить(пШаблон, КешПоШаблону);
		
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

Функция ОшибкаВЗамечании(Знач пОшибка)
	
	путьКФайлу = пОшибка.primaryLocation.filePath;
	
	Если Не ЗначениеЗаполнено(путьКФайлу) Тогда
		
		_Лог.Ошибка("Не указан путь для ошибки: %1. %2", пОшибка.ruleId, пОшибка.primaryLocation.message);
		
		Возврат Истина;
		
	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция ФайлНаПоддержке(Знач пОшибка)
	
	Если _УдалятьПоддержку = Неопределено Тогда
		
		Возврат Ложь;
		
	КонецЕсли;
	
	путьКФайлу = ОбеспечитьПутьКФайлуСИсходнымКодом(пОшибка.primaryLocation.filePath);
	
	текУровень = _ДанныеПоддержки.Уровень(путьКФайлу);
	
	Возврат текУровень <= _УдалятьПоддержку;
	
КонецФункции

Функция ИсключитьЗамечаниеФильтромПоПодсистеме(Знач пОшибка)
	
	Если Не _ДанныеФильтраПоПодсистемам.ЕстьОтбор
		И Не _ДанныеФильтраПоПодсистемам.ЕстьИсключения Тогда

		Возврат Ложь;

	КонецЕсли;
	
	путьКФайлу = ОбеспечитьПутьКФайлуСИсходнымКодом(пОшибка.primaryLocation.filePath);
	
	значениеКеша = _ДанныеФильтраПоПодсистемам.КешФайлов[путьКФайлу];

	Если Не значениеКеша = Неопределено Тогда

		Возврат значениеКеша;

	КонецЕсли;

	Если _ДанныеФильтраПоПодсистемам.ЕстьОтбор Тогда

		Для каждого цРазрешенныйОбъект Из _ДанныеФильтраПоПодсистемам.Отбор Цикл

			Если СтрНачинаетсяС(путьКФайлу, цРазрешенныйОбъект) Тогда

				_ДанныеФильтраПоПодсистемам.КешФайлов.Вставить(путьКФайлу, Ложь);
				Возврат Ложь;

			КонецЕсли;

		КонецЦикла;

	КонецЕсли;

	Если _ДанныеФильтраПоПодсистемам.ЕстьИсключения Тогда

		Для каждого цРазрешенныйОбъект Из _ДанныеФильтраПоПодсистемам.Исключения Цикл

			Если СтрНачинаетсяС(путьКФайлу, цРазрешенныйОбъект) Тогда

				_ДанныеФильтраПоПодсистемам.КешФайлов.Вставить(путьКФайлу, Истина);
				Возврат Истина;

			КонецЕсли;

		КонецЦикла;

	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция ОбеспечитьПутьКФайлуСИсходнымКодом(Знач пИмяФайла)
	
	существующийПуть = _ФайлыСИсходнымКодом[пИмяФайла];
	
	Если Не существующийПуть = Неопределено Тогда
		
		Возврат существующийПуть;
		
	КонецЕсли;
	
	абсолютныйПутьКФайлу = ОбщегоНазначения.АбсолютныйПуть(пИмяФайла);
	
	Если ОбщегоНазначения.ФайлСуществует(абсолютныйПутьКФайлу)
		ИЛИ ВРег(абсолютныйПутьКФайлу) = ВРег(СтрЗаменить(пИмяФайла, "\", "/")) // может быть указан абсолютный путь и файл не существовать
		Тогда
		
		_ФайлыСИсходнымКодом.Вставить(пИмяФайла, абсолютныйПутьКФайлу);
		Возврат абсолютныйПутьКФайлу;
		
	КонецЕсли;
	
	путьСУчетомКаталогаИсходников = _КаталогИсходников + "/" + пИмяФайла;
	
	абсолютныйПутьКФайлу = ОбщегоНазначения.АбсолютныйПуть(путьСУчетомКаталогаИсходников);
	
	Если ОбщегоНазначения.ФайлСуществует(абсолютныйПутьКФайлу) Тогда
		
		_ФайлыСИсходнымКодом.Вставить(пИмяФайла, абсолютныйПутьКФайлу);
		Возврат абсолютныйПутьКФайлу;
		
	КонецЕсли;
	
	_ФайлыСИсходнымКодом.Вставить(пИмяФайла, пИмяФайла);
	Возврат пИмяФайла;
	
КонецФункции

Процедура ПодготовитьФильтрПоПодсистемам()
	
	_ДанныеФильтраПоПодсистемам = Новый Структура;
	
	_ДанныеФильтраПоПодсистемам.Вставить("ЕстьОтбор", Ложь);
	_ДанныеФильтраПоПодсистемам.Вставить("ЕстьИсключения", Ложь);
	
	Если Не ЗначениеЗаполнено(_ФильтрПоПодсистемам) Тогда
		
		Возврат;
		
	КонецЕсли;
	
	инфоОКонфигурации = Новый ИнформацияОКонфигурации(_КаталогИсходников);
	
	_ФильтрПоПодсистемам = СтрЗаменить(_ФильтрПоПодсистемам, ";", ",");
	
	объектыОтбор = Новый Соответствие;
	объектыИсключения = Новый Соответствие;

	ОПЕРАЦИЯ_ДОБАВЛЕНИЕ = "+";
	ОПЕРАЦИЯ_ИСКЛЮЧЕНИЕ = "-";
	
	Для каждого цПодсистема Из СтрРазделить(_ФильтрПоПодсистемам, ",") Цикл
		
		имяПодсистемы = СтрЗаменить(цПодсистема, """", "");

		_лог.Информация("Обработка фрагмента: %1", имяПодсистемы);

		Если СтрНачинаетсяС(имяПодсистемы, "-") Тогда
			
			операция = ОПЕРАЦИЯ_ИСКЛЮЧЕНИЕ;
			
		Иначе
			
			операция = ОПЕРАЦИЯ_ДОБАВЛЕНИЕ;
			
		КонецЕсли;
		
		учитыватьРодительскиеПодсистемы = СтрНайти(имяПодсистемы, "^") > 0;
		учитыватьПодчиненныеПодсистемы = СтрНайти(имяПодсистемы, "*") > 0;
		
		имяПодсистемы = СтрЗаменить(имяПодсистемы, "+", "");
		имяПодсистемы = СтрЗаменить(имяПодсистемы, "-", "");
		имяПодсистемы = СтрЗаменить(имяПодсистемы, "*", "");
		имяПодсистемы = СтрЗаменить(имяПодсистемы, "^", "");
		
		объекты = инфоОКонфигурации.ОбъектыПодсистемы(имяПодсистемы, учитыватьПодчиненныеПодсистемы, учитыватьРодительскиеПодсистемы);

		Если операция = ОПЕРАЦИЯ_ИСКЛЮЧЕНИЕ Тогда

			ЗаполнитьСоответствиеПоМассиву(объектыИсключения, объекты);
			УдалитьЭлементыСоответствия(объектыОтбор, объекты);

			_ДанныеФильтраПоПодсистемам.Вставить("ЕстьИсключения", Истина);

			_лог.Информация("	Добавлены объекты к исключению по подсистеме %1: %2", имяПодсистемы, объекты.Количество());

		Иначе

			ЗаполнитьСоответствиеПоМассиву(объектыОтбор, объекты);
			УдалитьЭлементыСоответствия(объектыИсключения, объекты);

			_ДанныеФильтраПоПодсистемам.Вставить("ЕстьОтбор", Истина);

			_лог.Информация("	Добавлены объекты к отбору по подсистеме %1: %2", имяПодсистемы, объекты.Количество());

		КонецЕсли;
		
	КонецЦикла;

	ГенераторПутей = Новый Путь1СПоМетаданным(_КаталогИсходников);

	_ДанныеФильтраПоПодсистемам.Вставить("Отбор", МассивПутейОбъектов(объектыОтбор, ГенераторПутей));
	_ДанныеФильтраПоПодсистемам.Вставить("Исключения", МассивПутейОбъектов(объектыИсключения, ГенераторПутей));
	
	_ДанныеФильтраПоПодсистемам.Вставить("КешФайлов", Новый Соответствие);

	_лог.Информация("К отбору по подсистемам: %1", _ДанныеФильтраПоПодсистемам.Отбор.Количество());

	Для каждого цОбъект Из _ДанныеФильтраПоПодсистемам.Отбор Цикл

		_лог.Отладка("	Добавлено к отбору: %1", цОбъект);

	КонецЦикла;

	_лог.Информация("К исключению по подсистемам: %1", _ДанныеФильтраПоПодсистемам.Исключения.Количество());

	Для каждого цОбъект Из _ДанныеФильтраПоПодсистемам.Исключения Цикл

		_лог.Отладка("	Добавлено к исключению: %1", цОбъект);

	КонецЦикла;

КонецПроцедуры

Функция МассивПутейОбъектов(Знач пСоответствиеСПутями, Знач пГенераторПутей)

	массивПутей = Новый Массив;

	Для каждого цЭлемент Из пСоответствиеСПутями Цикл

		путьКОбъекту = пГенераторПутей.Путь(цЭлемент.Ключ);
		путьКОбъекту = ОбщегоНазначения.АбсолютныйПуть(путьКОбъекту);

		Если ОбщегоНазначения.КаталогСуществует(путьКОбъекту) Тогда

			массивПутей.Добавить(путьКОбъекту + "/");

		Иначе

			_Лог.Ошибка("Фильтр по подсистемам. Не удалось получить путь к <%1>. Полученный путь %2 не существует.", цЭлемент.Ключ, путьКОбъекту);

		КонецЕсли;

	КонецЦикла;

	Возврат массивПутей;
	
КонецФункции

Процедура ЗаполнитьСоответствиеПоМассиву(пСоответствие, Знач пМассив)
	
	Для каждого цЭлемент Из пМассив Цикл
		
		пСоответствие.Вставить(цЭлемент, Истина);
		
	КонецЦикла;
	
КонецПроцедуры

Процедура УдалитьЭлементыСоответствия(пСоответствие, Знач пМассив)
	
	Для каждого цЭлемент Из пМассив Цикл
		
		Если Не пСоответствие[цЭлемент] = Неопределено Тогда
			
			пСоответствие.Удалить(цЭлемент);
			
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

#КонецОбласти

