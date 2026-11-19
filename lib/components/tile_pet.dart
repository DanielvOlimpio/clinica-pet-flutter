import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pet.dart';

/// Item da lista: cada pet é exibido com **Card + ListTile**, ícone do tema
/// e o valor monetário formatado no padrão brasileiro pelo pacote `intl`.
///
/// Indicador visual Offline-first (ícone ao lado do valor):
/// - `Icons.cloud_done` (verde): registro **sincronizado** com a API.
/// - `Icons.cloud_upload` (laranja): registro **pendente** salvo apenas no
///   dispositivo, aguardando a sincronização manual.
class TilePet extends StatelessWidget {
  final Pet pet;
  final NumberFormat formatador;

  const TilePet({
    super.key,
    required this.pet,
    required this.formatador,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme cores = tema.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cores.primaryContainer,
          child: Icon(Icons.pets, color: cores.onPrimaryContainer),
        ),
        title: Text(
          pet.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          'Atendimento #${pet.id} • ${pet.especie}',
          style: TextStyle(color: cores.outline, fontSize: 13),
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Tooltip(
                message: pet.sincronizado
                    ? 'Sincronizado com a API'
                    : 'Pendente: salvo no dispositivo',
                child: Icon(
                  pet.sincronizado
                      ? Icons.cloud_done
                      : Icons.cloud_upload_outlined,
                  size: 18,
                  color: pet.sincronizado
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatador.format(pet.valor),
                style: TextStyle(
                  color: cores.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
