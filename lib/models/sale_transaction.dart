class SaleTransaction {
  final String date;
  final String society;
  final String bhk;
  final int sqft;
  final double salePriceCr;
  final double pricePerSqft;
  final String floor;
  final String varianceBadge;
  final bool isBargain;

  const SaleTransaction({
    required this.date,
    required this.society,
    required this.bhk,
    required this.sqft,
    required this.salePriceCr,
    required this.pricePerSqft,
    required this.floor,
    required this.varianceBadge,
    this.isBargain = false,
  });

  static List<SaleTransaction> sampleTransactions = const [
    SaleTransaction(
      date: '12 Aug 2026',
      society: 'Paras Tierea',
      bhk: '3BHK',
      sqft: 1750,
      salePriceCr: 1.46,
      pricePerSqft: 8342,
      floor: '14th',
      varianceBadge: '-2.1% Fair Value',
      isBargain: true,
    ),
    SaleTransaction(
      date: '04 Aug 2026',
      society: 'Gulshan Vivante',
      bhk: '3BHK',
      sqft: 1820,
      salePriceCr: 1.58,
      pricePerSqft: 8681,
      floor: '08th',
      varianceBadge: '+1.4% Avg Market',
    ),
    SaleTransaction(
      date: '28 Jul 2026',
      society: 'Exotica Fresco',
      bhk: '2BHK',
      sqft: 1250,
      salePriceCr: 1.08,
      pricePerSqft: 8640,
      floor: '19th',
      varianceBadge: 'Benchmark Price',
    ),
    SaleTransaction(
      date: '19 Jul 2026',
      society: 'Purvanchal Royal Park',
      bhk: '3BHK',
      sqft: 1950,
      salePriceCr: 1.82,
      pricePerSqft: 9333,
      floor: '05th',
      varianceBadge: '+6.2% Premium',
    ),
    SaleTransaction(
      date: '10 Jul 2026',
      society: 'Ajnara Daphmine',
      bhk: '3BHK',
      sqft: 1600,
      salePriceCr: 1.32,
      pricePerSqft: 8250,
      floor: '11th',
      varianceBadge: '-4.5% Bargain',
      isBargain: true,
    ),
  ];
}
