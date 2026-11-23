# Offline Fishing Camp for Android

Офлайн-прототип рыбалки на **Godot 3.5/GLES2** для Android-смартфонов.

## Что есть

- Сенсорный джойстик
- Озеро и берег
- Палатка, стол, костёр, магазин и стойка для удочек
- Девять процедурных рыб
- Базовый заброс удочки
- Счёт улова и монет
- Android export preset для ARM64 и ARMv7

## Запуск

1. Установить Godot 3.5 или совместимый Godot 3.x.
2. Открыть `project.godot`.
3. Запустить сцену `Main.tscn`.

## Сборка APK

1. Установить Android export templates для Godot 3.
2. Указать Android SDK/JDK в настройках редактора.
3. В `Project > Export` выбрать пресет `Android`.
4. Экспортировать `build/OfflineFishing.apk`.

Все ассеты генерируются проектом и не требуют загрузки во время игры.
