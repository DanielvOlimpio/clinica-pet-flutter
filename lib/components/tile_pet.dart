import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pet.dart';

/// Item da lista: cada pet é exibido com **Card + ListTile**, ícone do tema
/// e o valor monetário formatado no padrão brasileiro pelo pacote `intl`.
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
          child: Text(
            formatador.format(pet.valor),
            style: TextStyle(
              color: cores.primary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}
