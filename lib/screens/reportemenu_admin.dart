import 'package:flutter/material.dart';
import 'package:paulette/screens/estadistica_admin.dart';
import 'package:paulette/screens/ingreso_reporte.dart';
import 'package:paulette/screens/menu_admin.dart';

class ReportemenuAdmin extends StatefulWidget {
  const ReportemenuAdmin({super.key});

  @override
  State<ReportemenuAdmin> createState() => _ReportemenuAdminState();
}
String diaSeleccionado = 'LUNES';
class _ReportemenuAdminState extends State<ReportemenuAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
 
      appBar: AppBar(
        elevation: 5.0,
        title: Text(
          "REPORTES",
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

    
      backgroundColor: Colors.grey[100], 

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            SizedBox(height: 10), 

            // TÍTULO SECUNDARIO: SEMANAL
            Center(
              child: Text(
                "SEMANAL",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 30), 
            //  BLOQUE DE BOTONES DE DÍAS (Hice un Center para centrar el bloque)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LUNES (Seleccionador)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context)=>IngresoReporte()),
                );
                    },
                    child: Container(
                      width: 150, 
                      height: 40, 
                      margin: EdgeInsets.only(bottom: 5), 
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'LUNES' ? Colors.grey[400] : Colors.white, 
                      ),
                      child: Center(
                        child: Text(
                          "LUNES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // --- MARTES ---
                  InkWell(
                    onTap: () {
                      setState(() {
                        diaSeleccionado = 'MARTES';
                      });
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'MARTES' ? Colors.grey[400] : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "MARTES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // --- MIÉRCOLES ---
                  InkWell(
                    onTap: () {
                      setState(() {
                        diaSeleccionado = 'MIÉRCOLES';
                      });
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'MIÉRCOLES' ? Colors.grey[400] : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "MIÉRCOLES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // --- JUEVES ---
                  InkWell(
                    onTap: () {
                      setState(() {
                        diaSeleccionado = 'JUEVES';
                      });
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'JUEVES' ? Colors.grey[400] : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "JUEVES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // --- VIERNES ---
                  InkWell(
                    onTap: () {
                      setState(() {
                        diaSeleccionado = 'VIERNES';
                      });
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'VIERNES' ? Colors.grey[400] : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "VIERNES",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  
                  // --- SÁBADO ---
                  InkWell(
                    onTap: () {
                      setState(() {
                        diaSeleccionado = 'SÁBADO';
                      });
                    },
                    child: Container(
                      width: 150,
                      height: 40,
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        color: diaSeleccionado == 'SÁBADO' ? Colors.grey[400] : Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          "SÁBADO",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
            
            SizedBox(height: 80), 

            //  BOTÓN ESTADÍSTICA 
            Center(
              child: InkWell(
                onTap: () {
                   Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context)=>EstadisticaAdmin()),
                );
                  // Acción para Estadística
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  width: 150, 
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black, 
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      "Estadística",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40), 

          ],
        ),
      ),

      persistentFooterButtons: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton(
            onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context)=>MenuAdmin()),
                );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(0xFF000000),
              foregroundColor: const Color(0xFFFFFFFF),
              elevation: 5,
            ),
            child: const Text(
              "Inicio",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],

 
    );
  }
}