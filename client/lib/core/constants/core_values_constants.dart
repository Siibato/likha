class CoreValueStatement {
  final int id;
  final String coreValue;
  final String statement;

  const CoreValueStatement({
    required this.id,
    required this.coreValue,
    required this.statement,
  });
}

const coreValueStatements = [
  CoreValueStatement(id: 1, coreValue: 'Maka-Diyos', statement: "Expresses one's spiritual beliefs while respecting those of others"),
  CoreValueStatement(id: 2, coreValue: 'Makatao', statement: 'Demonstrates and expresses pride in being a Filipino without looking down on others'),
  CoreValueStatement(id: 3, coreValue: 'Maka-Kalikasan', statement: 'Shows care and concern for the environment'),
  CoreValueStatement(id: 4, coreValue: 'Maka-bansa', statement: 'Demonstrates pride in being a Filipino without looking down on others'),
  CoreValueStatement(id: 5, coreValue: 'Maka-Diyos', statement: 'Shows adherence to ethical principles by upholding truth and justice at all times'),
  CoreValueStatement(id: 6, coreValue: 'Makatao', statement: 'Listens attentively and responds appropriately to the opinions, ideas, and views of others'),
  CoreValueStatement(id: 7, coreValue: 'Maka-Kalikasan', statement: 'Demonstrates resourcefulness and creativity in solving problems'),
  CoreValueStatement(id: 8, coreValue: 'Maka-bansa', statement: 'Shows commitment to the ideals of democracy and nationalism'),
  CoreValueStatement(id: 9, coreValue: 'Maka-Diyos', statement: 'Exhibits a deep sense of love for and service to the community and country'),
  CoreValueStatement(id: 10, coreValue: 'Makatao', statement: 'Shows respect for and understanding of differences in culture, religion, and beliefs'),
  CoreValueStatement(id: 11, coreValue: 'Maka-Kalikasan', statement: 'Exhibits a sense of responsibility for the sustainable use of resources'),
  CoreValueStatement(id: 12, coreValue: 'Maka-bansa', statement: 'Exhibits a deep sense of patriotism and love for the country'),
];

const coreValueNames = ['Maka-Diyos', 'Makatao', 'Maka-Kalikasan', 'Maka-bansa'];

const coreValueMarkings = ['AO', 'SO', 'NO', 'RO'];

List<CoreValueStatement> statementsForCoreValue(String name) {
  return coreValueStatements.where((s) => s.coreValue == name).toList();
}
