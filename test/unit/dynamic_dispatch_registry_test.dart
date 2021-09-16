@Tags(['unit', 'util'])

import 'dart:ui' show VoidCallback;

import 'package:test/test.dart';

import 'package:lunofono_player/src/dynamic_dispatch_registry.dart';

class Base {}

class Item extends Base {
  int? x;
}

class NoSubClass {}

void main() {
  group('DynamicLibrary', () {
    group('from empty', () {
      late DynamicDispatchRegistry<Base, VoidCallback> registry;
      void baseFunction() {}
      void itemFunction1() {}
      void itemFunction2() {}

      setUp(() {
        registry = DynamicDispatchRegistry<Base, VoidCallback>();
      });

      test('is empty', () {
        expect(registry.isEmpty, isTrue);
      });

      test('getting the function for an unregistered type returns null', () {
        var function = registry.getFunction(Item());
        expect(registry.isEmpty, isTrue);
        expect(function, isNull);
        expect(registry.getFunction(Base()), isNull);
      });

      test('unregistering an unregistered type returns null', () {
        final oldRegisteredFunction = registry.unregister(Base);
        expect(registry.isEmpty, isTrue);
        expect(oldRegisteredFunction, isNull);
      });

      test('registering a superclass returns the right functions', () {
        final old = registry.register(Base, baseFunction);
        expect(old, isNull);
        expect(registry.isEmpty, isFalse);
        expect(registry.getFunction(Base()), baseFunction);
        expect(registry.getFunction(Item()), isNull);
      });

      test('registering a subclass returns the right functions', () {
        final old = registry.register(Item, itemFunction1);
        expect(registry.isEmpty, isFalse);
        expect(old, isNull);
        expect(registry.getFunction(Item()), itemFunction1);
        expect(registry.getFunction(Base()), isNull);
      });

      test('registering a subclass and subclass returns the right functions',
          () {
        registry.register(Base, baseFunction);
        final old = registry.register(Item, itemFunction1);
        expect(old, isNull);
        expect(registry.isEmpty, isFalse);
        expect(registry.getFunction(Item()), itemFunction1);
        expect(registry.getFunction(Base()), baseFunction);
      });

      test('can register and unregister functions', () {
        registry.register(Item, itemFunction1);
        final old = registry.unregister(Item);
        expect(old, itemFunction1);
        expect(registry.isEmpty, isTrue);
      });

      test('re-registering returns the old function and used the new one', () {
        registry.register(Item, itemFunction1);
        final old = registry.register(Item, itemFunction2);
        expect(old, itemFunction1);
        expect(registry.isEmpty, isFalse);
        expect(registry.getFunction(Item()), itemFunction2);
      });

      test('toString()', () {
        expect(registry.toString(),
            'DynamicDispatchRegistry<Base, () => void>({})');
        registry.register(Base, baseFunction);
        expect(
            registry.toString(),
            'DynamicDispatchRegistry<Base, () => void>'
            '({Base: Closure: () => void})');
      });
    });
  });
}
