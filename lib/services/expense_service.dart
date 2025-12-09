import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final CollectionReference _expensesRef =
      FirebaseFirestore.instance.collection("expenses");

  // Añadir gasto
  Future<void> addExpense(String title, double amount, DateTime date) async {
    await _expensesRef.add({
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    });
  }

  // Obtener todos los gastos
  Stream<List<ExpenseModel>> getAllExpenses() {
    return _expensesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}