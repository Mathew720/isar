import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/internal.dart';
import 'package:isar/src/isar_collection.dart';
import 'package:isar/src/isar_object.dart';
import 'package:isar/src/native/bindings/bindings.dart';
import 'package:isar/src/native/isar_impl.dart';
import 'package:isar/src/native/type_adapter.dart';
import 'package:isar/src/native/util/native_call.dart';

class IsarCollectionImpl<T extends IsarObject> extends IsarCollection<T> {
  final IsarImpl isar;
  final TypeAdapter _adapter;
  final Pointer _collection;

  IsarCollectionImpl(this.isar, this._adapter, this._collection);

  @override
  Future<T> get(int id) {
    return isar.optionalTxn(false, (txn) {
      var rawObjPtr = IsarBindings.obj;
      var rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      nativeCall(isarBindings.getObject(_collection, txn, rawObjPtr));

      T object = _adapter.deserialize(rawObj);
      object.init(rawObj.oid, this);
      return object;
    });
  }

  @override
  Future<void> put(T object) {
    return isar.optionalTxn(true, (txn) {
      var rawObjPtr = IsarBindings.obj;
      var rawObj = rawObjPtr.ref;
      _adapter.serialize(object, rawObj);

      nativeCall(isarBindings.putObject(_collection, txn, rawObjPtr));

      object.init(rawObj.oid, this);

      free(rawObj.data);
    });
  }

  @override
  Future<void> putAll(List<T> objects) {
    return isar.optionalTxn(true, (txn) {
      var rawObjsPtr = allocate<RawObject>(count: objects.length);
      for (var i = 0; i < objects.length; i++) {
        var rawObj = rawObjsPtr.elementAt(i).ref;
        _adapter.serialize(objects[i], rawObj);
      }

      nativeCall(isarBindings.putObjects(_collection, txn, rawObjsPtr));

      for (var i = 0; i < objects.length; i++) {
        var rawObj = rawObjsPtr.elementAt(i).ref;
        objects[i].init(rawObj.oid, this);
        free(rawObj.data);
      }

      free(rawObjsPtr);
    });
  }

  @override
  Future<void> delete(T object) {
    return isar.optionalTxn(true, (txn) {
      var rawObjPtr = IsarBindings.obj;
      var rawObj = rawObjPtr.ref;
      rawObj.oid = object.id;

      nativeCall(isarBindings.deleteObject(_collection, txn, rawObjPtr));
      object.init(null, null);
    });
  }
}
