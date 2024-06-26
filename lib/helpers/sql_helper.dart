import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class SqlHelper {
  Database? db;

  Future<void> init() async {
    try {
      if (kIsWeb) {
        var factory = databaseFactoryFfiWeb;
        db = await factory.openDatabase('pos.db');
      } else {
        db = await openDatabase(
          'pos.db',
          version: 1,
          onCreate: (db, version) {
            print('database created successfully');
          },
        );
      }
    } catch (e) {
      print('Error in creating database: $e');
    }
  }

  Future<void> registerForeignKesys() async {
    await db!.rawQuery(" PRAGMA foreign_keys = ON");
    var result = await db!.rawQuery(" PRAGMA foreign_keys ");
    print('foreign keys result :$result ');
  }

  Future<bool> createTables() async {
    try {
      await registerForeignKesys();
      var batch = db!.batch();
      batch.rawQuery("""
      PRAGMA foreign_keys = ON
      """);
      batch.rawQuery("""
      PRAGMA foreign_keys 
      """);
      batch.execute("""
        Create table if not exists categories(
          id integer primary key,
          name text not null,
          description text not null
          ) 
          """);

      batch.execute("""
        Create table if not exists products(
          id integer primary key,
          name text not null,
          description text not null,
          price double not null,
          stock integer not null,
          isAvaliable boolean not null,
          image text,
          categoryId integer not null,
          foreign key(categoryId) references categories(id)
          on delete restrict
          ) 
          """);

      batch.execute("""
        Create table if not exists clients(
          id integer primary key,
          name text not null,
          email text,
          phone text,
          address text
          ) 
          """);
      batch.execute("""
        Create table if not exists orders(
          id integer primary key,
          label text,
          totalPrice real,
          discount real,
          clientId integer not null,
          orderDate TEXT,
          foreign key(clientId) references clients(id)
          on delete restrict
          ) 
          """);
      batch.execute("""
        Create table if not exists orderProductItems(
         orderId integer,
         productCount integer,
         productId integer,
          foreign key(productId) references products(id)
          on delete restrict
          ) 
          """);

      batch.execute("""
        CREATE TABLE IF NOT EXISTS exchangeRates(
          id INTEGER PRIMARY KEY,
          currency TEXT NOT NULL,
          rate REAL NOT NULL
        ) 
      """);

      batch.execute("""
        INSERT INTO exchangeRates(currency, rate)
        VALUES('USD_TO_EGP', 60.0)
      """);

      var result = await batch.commit();
      print('resuts $result');
      return true;
    } catch (e) {
      print('Error in creating table: $e');
      return false;
    }
  }
  Future<double?> getExchangeRate(String currency) async {
    try {
      var result = await db!.rawQuery("""
        SELECT rate FROM exchangeRates WHERE currency = '$currency'
      """);
      if (result.isNotEmpty) {
        return result.first['rate'] as double?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
      return null;
    }
  }
  Future<void> backupDatabase() async {
    try {
      // Get the path to the database file
      var databasesPath = await getDatabasesPath();
      String dbPath = join(databasesPath, 'pos.db');

      // Get the path to the backup directory
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String backupPath = join(documentsDirectory.path, 'backup_database.db');

      // Copy the database file to the backup location
      File sourceFile = File(dbPath);
      File backupFile = File(backupPath);
      await backupFile.writeAsBytes(await sourceFile.readAsBytes());

      print('Database backup created at $backupPath');
    } catch (e) {
      print('Error creating database backup: $e');
    }
  }
  Future<void> restoreDatabase() async {
    try {
      // Get the path to the database file
      var databasesPath = await getDatabasesPath();
      String dbPath = join(databasesPath, 'your_database.db');

      // Get the path to the backup directory
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String backupPath = join(documentsDirectory.path, 'backup_database.db');

      // Copy the backup file to the database location
      File backupFile = File(backupPath);
      File dbFile = File(dbPath);
      await dbFile.writeAsBytes(await backupFile.readAsBytes());

      print('Database restored from backup at $backupPath');
    } catch (e) {
      print('Error restoring database from backup: $e');
    }
  }
}
