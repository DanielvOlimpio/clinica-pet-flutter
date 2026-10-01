import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Componente **Editor** (padrão do Projeto Bank).
///
/// Campo de entrada reutilizável que recebe o `TextEditingController` da
/// tela, o rótulo, a dica, o ícone do tema e, opcionalmente, a quantidade de
/// casas decimais, um prefixo e uma função de validação.
class Editor extends StatelessWidget {
  /// Controlador do texto digitado pelo usuário.
  final TextEditingController controlador;

  /// Rótulo exibido no campo.
  final String texto;

  /// Dica (placeholder) exibida quando o campo está vazio.
  final String dicaTexto;

  /// Ícone do tema exibido à esquerda do campo.
  final IconData icone;

  /// Oculta o texto digitado (ex.: senhas).
  final bool obscure;

  /// Permite escrever várias linhas.
  final bool expand;

  /// Quantidade de casas decimais aceitas.
  ///
  /// `null` = texto livre; `0` = somente números inteiros; `> 0` = números com
  /// até essa quantidade de casas decimais.
  final int? numeroDecimal;

  /// Texto fixo exibido antes do valor digitado (ex.: `R$ `).
  final String? prefixoTexto;

  /// Validação do campo (retorna a mensagem de erro ou `null`).
  final String? Function(String?)? validador;

  const Editor({
    super.key,
    required this.controlador,
    required this.texto,
    required this.dicaTexto,
    required this.icone,
    this.obscure = false,
    this.expand = false,
    this.numeroDecimal,
    this.prefixoTexto,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: controlador,
        obscureText: obscure,
        validator: validador,
        maxLines: expand ? null : 1,
        keyboardType: (numeroDecimal != null)
            ? TextInputType.numberWithOptions(decimal: numeroDecimal! > 0)
            : TextInputType.text,
        inputFormatters: (numeroDecimal != null)
            ? <TextInputFormatter>[_FiltroNumerico(numeroDecimal!)]
            : null,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          icon: Icon(icone),
          labelText: texto,
          hintText: dicaTexto,
          prefixText: prefixoTexto,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Impede a digitação de caracteres inválidos: apenas números, e no máximo
/// [decimais] casas decimais, aceitando `,` ou `.` como separador.
class _FiltroNumerico extends TextInputFormatter {
  final int decimais;

  const _FiltroNumerico(this.decimais);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final String texto = novo.text;
    if (texto.isEmpty) {
      return novo;
    }

    final RegExp expressao = decimais > 0
        ? RegExp('^\\d{1,7}([.,]\\d{0,$decimais})?\$')
        : RegExp(r'^\d{1,7}$');

    return expressao.hasMatch(texto) ? novo : anterior;
  }
}
