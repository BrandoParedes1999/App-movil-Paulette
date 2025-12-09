import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Importa el mapa
import 'package:latlong2/latlong.dart'; // Importa las coordenadas

class UbicacionOsmScreen extends StatelessWidget {
  const UbicacionOsmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    final LatLng miUbicacion = LatLng(18.64481, -91.7897874);

    return Scaffold(
      appBar: AppBar(
        elevation: 5.0,
        title: Text("Ubicación de Paulette"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          height: 500,
          width: 500,
          decoration: BoxDecoration(
           
            border: Border.all(
              color: const Color.fromARGB(255, 45, 4, 230), 
              width: 3.0, 
            ),

           
            borderRadius: BorderRadius.circular(15.0), 
          ),

          
          child: ClipRRect(
            
            borderRadius: BorderRadius.circular(15.0),

            child: FlutterMap(
              
              options: MapOptions(
                initialCenter: miUbicacion,
                initialZoom: 16.0,
              ),

              
              children: [
                
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.paulette',
                ),

                
                MarkerLayer(
                  markers: [
                    Marker(
                      point: miUbicacion, 
                      width: 80,
                      height: 80,
                      
                      child: Tooltip(
                        message: 'Paulette Estética',
                        child: Icon(
                          Icons.location_pin,
                          color: const Color.fromARGB(255, 45, 4, 230),
                          size: 45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      persistentFooterButtons: [
        Row(
          children: [
            Spacer(),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_sharp),
                    Text("Cambiar Ubicación", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
