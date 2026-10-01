# Clínica Pet — Avaliação Prática (Programação para Dispositivos Móveis II)

Aplicação remota em **Flutter** adaptada do **Projeto Bank** ao tema **Clínica Pet**
(registro de atendimentos veterinários).

> **Somente dados em memória:** a aplicação **não utiliza persistência de dados**
> (sem `sqflite`, `shared_preferences` etc.) e a camada `database` do Projeto Bank
> **não é utilizada**.

---

## 1. Tema escolhido

| Item | Descrição |
| --- | --- |
| Nome do aplicativo | **Clínica Pet** |
| Entidade | `Pet` (adaptação da classe `Transferencia`) |
| Atributos | `id` (`int`), `nome` (`String`), `especie` (`String`), `valor` (`double`) |
| Valor monetário | Valor da consulta, exibido como `R$ 0,00` (pacote `intl`) |
| Ícone do tema | `Icons.pets` |

---

## 2. Estrutura do projeto (padrão estudado em aula)

```
clinica_pet/
├── lib/
│   ├── main.dart                      # MaterialApp / ThemeData (personalização do tema)
│   ├── models/
│   │   └── pet.dart                   # Modelo da entidade (id int + valor double + toString)
│   ├── components/
│   │   ├── editor.dart                # Componente Editor (TextField + InputFormatter)
│   │   └── tile_pet.dart              # Card + ListTile de cada registro da lista
│   └── telas/
│       ├── lista_pets.dart            # Tela de lista (ListView.builder + FAB)
│       └── formulario_pet.dart        # Tela de formulário (controllers + tryParse)
├── test/
│   └── widget_test.dart               # Testes automatizados da aplicação
├── evidencias/
│   ├── formulario.png                 # Tela de formulário preenchida
│   └── lista.png                      # Tela de lista com o novo registro
├── android/                           # Projeto Android (padrão do flutter create)
└── web/                               # Projeto Web (padrão do flutter create)
```

---

## 3. Regras obrigatórias x implementação

| # | Regra obrigatória | Onde foi implementada |
| --- | --- | --- |
| 1 | Projeto Bank como ponto de partida, mantendo o padrão (main, models, Editor, lista e formulário) | Toda a estrutura em `lib/` |
| 2 | Não utilizar persistência nem a camada `database` | Nenhum pacote de banco/persistência no `pubspec.yaml`; a lista é um `List<Pet>` em memória (`telas/lista_pets.dart`) |
| 3 | Adaptar `Transferencia` para a entidade do tema | `models/pet.dart` (classe `Pet`) |
| 4 | Modelo com valor monetário `double` e identificador numérico `int` | `Pet.id` (`int`) e `Pet.valor` (`double`) |
| 5 | Lista com `ListView.builder` e itens com `Card` / `ListTile` | `telas/lista_pets.dart` (ListView.builder) e `components/tile_pet.dart` (Card + ListTile) |
| 6 | `TextEditingController`, componente `Editor` e conversões seguras com `tryParse` | `telas/formulario_pet.dart` (4 controllers) + `components/editor.dart`; `int.tryParse` e `double.tryParse` no método `_salvar()` |
| 7 | Navegar com `Navigator.push` / `MaterialPageRoute` e retornar o objeto com `Navigator.pop` | `telas/lista_pets.dart` (`Navigator.push<Pet>`) e `telas/formulario_pet.dart` (`Navigator.pop(context, pet)`) |
| 8 | Atualizar a lista com `setState` e usar `Future.delayed()` antes da inclusão | `telas/lista_pets.dart` (`Future.delayed(Duration(seconds: 1), ...)` seguido de `setState`) |
| 9 | Formatar o valor monetário com `intl` no padrão brasileiro | `NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2)` |
| 10 | Personalizar `MaterialApp` / `ThemeData`, textos, ícones e nomes | `main.dart` (tema teal, sem `debugShowCheckedModeBanner`), AppBar, textos e ícones do tema (`Icons.pets`, `Icons.medical_services_outlined`, `Icons.payments_outlined`) — nenhuma referência ao Bank |
| 11 | Pelo menos dois registros iniciais em memória | `Thor` (Cão, R$ 180,00) e `Mia` (Gato, R$ 120,50) em `telas/lista_pets.dart` |
| 12 | Criar o objeto somente quando os dados forem válidos | `Form` + `GlobalKey<FormState>` e validadores; a validação é refeita com `tryParse` antes de instanciar `Pet` |

### Pontos de destaque

* **Objeto criado apenas com dados válidos:** o formulário valida os campos e só
  então executa `int.tryParse` / `double.tryParse`; se qualquer conversão
  retornar `null`, o usuário recebe um `SnackBar` e nada é criado.
* **Entrada numérica protegida:** o `Editor` usa um `TextInputFormatter` que aceita
  somente números (com até 2 casas decimais) nos campos `id` e `valor`.
* **Padrão brasileiro:** o `double.tryParse` recebe o texto com a vírgula
  substituída por ponto (`replaceAll(',', '.')`) e a exibição usa
  `NumberFormat` com `locale: 'pt_BR'` (R$ 199,90).
* **Atualização dinâmica:** após salvar, a tela volta para a lista, o item entra
  com `setState` dentro de um `Future.delayed()` de 1 segundo e um `SnackBar`
  confirma o cadastro — sem reiniciar o aplicativo.

---

## 4. Como executar

Pré-requisito: Flutter 3.27+ (o projeto foi desenvolvido com Flutter 3.47.5 / Dart 3.13).

```bash
# 1. Instalar as dependências
flutter pub get

# 2. Executar no navegador (usado para gerar as evidências)
flutter run -d chrome

# 3. Ou executar em um dispositivo/emulador Android
flutter run

# 4. Gerar a versão de produção para Web
flutter build web --release
```

Testes automatizados e análise estática:

```bash
flutter analyze   # deve retornar "No issues found!"
flutter test      # 3 testes devem passar
```

---

## 5. Evidências

As imagens foram geradas executando a aplicação no navegador (Chrome) em um
viewport de celular (440 x 920 px), durante uma única sessão:

1. `evidencias/formulario.png` — tela **Cadastrar atendimento** com os campos preenchidos
   (id `3`, nome `Bidu`, espécie `Cão` e valor `199,90`).
2. `evidencias/lista.png` — tela **Clínica Pet** após confirmar o cadastro, já
   exibindo o novo registro **Bidu — Atendimento #3 • Cão — R$ 199,90** e o
   total atualizado para **R$ 500,40** (sem reiniciar o aplicativo).

---

## 6. Dependências

```yaml
dependencies:
  flutter:          # SDK
  cupertino_icons: ^1.0.8
  intl: ^0.20.2     # formatação monetária no padrão brasileiro
```

Não há dependência de banco de dados nem de armazenamento — todos os dados
existem apenas em memória durante a execução do aplicativo.
