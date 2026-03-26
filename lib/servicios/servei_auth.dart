
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'habit_service.dart';

class ServeiAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registrarUsuariAmbEmailPassword(String email, String password, String username) async{
  
    try {

      //al crear un registro de usuario tambien le hace el login de usuario automaticamente, por eso guardamos la credencial del usuario que se ha registrado
      UserCredential credencialUsuari= await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid=credencialUsuari.user!.uid;

      try {
        await _firestore.collection("usuaris").doc(uid).set(
          {
          "uid": uid,
          "email": email,
          "nom": username,
          "data_registre": FieldValue.serverTimestamp(),
          "totalHabitosCompletados": 0,
          }
        );
        // Crear los 3 hábitos por defecto
        await HabitService().crearHabitosDefecto();
      } catch (e) {
        // Si falla Firestore pero Auth fue exitoso, aún consideramos el registro exitoso
        print("Advertencia: No se pudieron guardar todos los datos en Firestore: $e");
      }

      return null;//todo bien

    } on FirebaseAuthException catch (e){

      switch (e.code){
        case "email-already-in-use":
          return "Aquest email ja està en ús";
        case "invalid-email":
          return "Aquest email no és vàlid";
        case "operation-not-allowed":
          return "Operació no permesa";
        case "weak-password":
          return "La contrasenya és massa feble";
        default:
          return "Error desconegut: ${e.message}";
      }

    }on FirebaseException catch (e){

      switch (e.code){
        default:
          return "Error desconegut: ${e.message}";
      }


    }
  }
  Future<String?> iniciarSesionAmbEmailPassword(String email, String password) async {
    try {
      // Intentar autenticarse con Firebase Auth
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Login exitoso
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "No existe cuenta con este correo";
        case "wrong-password":
          return "Contraseña incorrecta";
        case "invalid-credential":
          return "Email o contraseña incorrectos";
        case "user-disabled":
          return "Esta cuenta ha sido deshabilitada";
        case "invalid-email":
          return "Email inválido";
        default:
          return "Error en el inicio de sesión: ${e.message}";
      }
    } on FirebaseException catch (e) {
      return "Error desconegut: ${e.message}";
    }
  }

  Future<void> ferLogout() async {
    await _auth.signOut();
  }

  // Obtener el usuario actual
  User? obtenerUsuarioActual() {
    return _auth.currentUser;
  }

  // Obtener datos del usuario desde Firestore
  Future<Map<String, dynamic>?> obtenerDatosUsuari(String uid) async {
    try {
      final doc = await _firestore.collection("usuaris").doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}