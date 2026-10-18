import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_managment_app/core/errors/failures.dart';
import 'package:gym_managment_app/features/finance/domain/entities/finance_enums.dart';
import 'package:gym_managment_app/features/finance/domain/repositories/expense_repository.dart';
import 'package:gym_managment_app/features/finance/domain/repositories/payment_repository.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/add_expense.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/add_payment.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/void_expense.dart';
import 'package:gym_managment_app/features/finance/domain/usecases/void_payment.dart';

class FakePaymentRepository implements PaymentRepository {
  final List<Map<String, dynamic>> payments = [];
  int nextId = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, int>> addPayment({
    required int memberId,
    int? subscriptionId,
    int? periodId,
    int? installmentId,
    required double amount,
    PaymentMethod? method,
    required DateTime paidAt,
    String? note,
  }) async {
    final id = nextId++;
    payments.add({
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'method': method,
      'paidAt': paidAt,
      'note': note,
      'voidedAt': null,
    });
    return Right(id);
  }

  @override
  Future<Either<Failure, Unit>> voidPayment(int paymentId, {String? reason}) async {
    final payment = payments.firstWhere((p) => p['id'] == paymentId, orElse: () => {});
    if (payment.isEmpty) return const Left(DatabaseFailure('الدفعة غير موجودة'));
    payment['voidedAt'] = DateTime.now();
    payment['voidReason'] = reason;
    return const Right(unit);
  }
}

class FakeExpenseRepository implements ExpenseRepository {
  final List<Map<String, dynamic>> expenses = [];
  int nextId = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, int>> addExpense({
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  }) async {
    final id = nextId++;
    expenses.add({
      'id': id,
      'category': category,
      'customLabel': customLabel,
      'amount': amount,
      'method': method,
      'date': date,
      'note': note,
      'voidedAt': null,
    });
    return Right(id);
  }

  @override
  Future<Either<Failure, Unit>> updateExpense(
    int expenseId, {
    required ExpenseCategory category,
    String? customLabel,
    required double amount,
    PaymentMethod? method,
    required DateTime date,
    String? note,
  }) async {
    final expense = expenses.firstWhere((e) => e['id'] == expenseId, orElse: () => {});
    if (expense.isEmpty) return const Left(DatabaseFailure('المصروف غير موجود'));
    expense['category'] = category;
    expense['customLabel'] = customLabel;
    expense['amount'] = amount;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> voidExpense(int expenseId) async {
    final expense = expenses.firstWhere((e) => e['id'] == expenseId, orElse: () => {});
    if (expense.isEmpty) return const Left(DatabaseFailure('المصروف غير موجود'));
    expense['voidedAt'] = DateTime.now();
    return const Right(unit);
  }
}

void main() {
  group('AddPayment UseCase', () {
    late FakePaymentRepository repository;
    late AddPayment useCase;

    setUp(() {
      repository = FakePaymentRepository();
      useCase = AddPayment(repository);
    });

    test('fails validation when amount is zero or negative', () async {
      final resultZero = await useCase(AddPaymentParams(
        memberId: 1,
        amount: 0,
        paidAt: DateTime.now(),
      ));
      expect(resultZero.isLeft(), isTrue);
      resultZero.match(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );

      final resultNeg = await useCase(AddPaymentParams(
        memberId: 1,
        amount: -50,
        paidAt: DateTime.now(),
      ));
      expect(resultNeg.isLeft(), isTrue);
    });

    test('succeeds with valid payment params', () async {
      final result = await useCase(AddPaymentParams(
        memberId: 1,
        amount: 150.0,
        method: PaymentMethod.cash,
        paidAt: DateTime.now(),
        note: 'دفعة أولى',
      ));

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('Should succeed'),
        (id) => expect(id, 1),
      );
      expect(repository.payments.length, 1);
      expect(repository.payments.first['amount'], 150.0);
    });
  });

  group('VoidPayment UseCase', () {
    late FakePaymentRepository repository;
    late VoidPayment useCase;

    setUp(() async {
      repository = FakePaymentRepository();
      useCase = VoidPayment(repository);
      await repository.addPayment(
        memberId: 1,
        amount: 200,
        paidAt: DateTime.now(),
      );
    });

    test('voids payment with reason', () async {
      final result = await useCase(1, reason: 'دفع بالخطأ');
      expect(result.isRight(), isTrue);
      expect(repository.payments.first['voidedAt'], isNotNull);
      expect(repository.payments.first['voidReason'], 'دفع بالخطأ');
    });
  });

  group('AddExpense UseCase', () {
    late FakeExpenseRepository repository;
    late AddExpense useCase;

    setUp(() {
      repository = FakeExpenseRepository();
      useCase = AddExpense(repository);
    });

    test('fails validation when amount <= 0', () async {
      final res = await useCase(AddExpenseParams(
        category: ExpenseCategory.electricity,
        amount: 0,
        date: DateTime.now(),
      ));
      expect(res.isLeft(), isTrue);
    });

    test('fails validation when category is other and customLabel is empty', () async {
      final res = await useCase(AddExpenseParams(
        category: ExpenseCategory.other,
        customLabel: '   ',
        amount: 100,
        date: DateTime.now(),
      ));
      expect(res.isLeft(), isTrue);
      res.match(
        (failure) => expect(failure.message, contains('أخرى')),
        (_) => fail('Should fail'),
      );
    });

    test('succeeds with valid expense params', () async {
      final res = await useCase(AddExpenseParams(
        category: ExpenseCategory.maintenance,
        amount: 120.0,
        method: PaymentMethod.transfer,
        date: DateTime.now(),
        note: 'تصليح السير',
      ));
      expect(res.isRight(), isTrue);
      expect(repository.expenses.length, 1);
      expect(repository.expenses.first['amount'], 120.0);
    });
  });

  group('VoidExpense UseCase', () {
    late FakeExpenseRepository repository;
    late VoidExpense useCase;

    setUp(() async {
      repository = FakeExpenseRepository();
      useCase = VoidExpense(repository);
      await repository.addExpense(
        category: ExpenseCategory.water,
        amount: 50,
        date: DateTime.now(),
      );
    });

    test('voids expense record', () async {
      final res = await useCase(1);
      expect(res.isRight(), isTrue);
      expect(repository.expenses.first['voidedAt'], isNotNull);
    });
  });
}
