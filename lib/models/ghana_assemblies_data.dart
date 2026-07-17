import 'assembly.dart';
import 'region.dart';

/// A **starter set** of Ghana's Metropolitan/Municipal/District Assemblies,
/// keyed by [Region] — not the full ~261-assembly list. Ghana's exact MMDA
/// roster has shifted over successive Legislative Instruments, so rather
/// than risk embedding subtly wrong "official" data into a system meant to
/// be pitched nationally, this ships 2-4 real, high-confidence assemblies
/// per region (the regional capital plus a few well-known neighbours) and
/// leaves the map trivially extensible.
///
/// **Before real deployment**: verify and expand this list against an
/// authoritative source (Ghana's Ministry of Local Government, Decentralisation
/// and Rural Development, or the Local Governance Act's assembly schedule).
final Map<Region, List<Assembly>> ghanaAssemblies = {
  Region.greaterAccra: const [
    Assembly(
      name: 'Accra',
      type: AssemblyType.metropolitan,
      region: Region.greaterAccra,
    ),
    Assembly(
      name: 'Tema',
      type: AssemblyType.metropolitan,
      region: Region.greaterAccra,
    ),
    Assembly(
      name: 'Ga West',
      type: AssemblyType.municipal,
      region: Region.greaterAccra,
    ),
    Assembly(
      name: 'Ashaiman',
      type: AssemblyType.municipal,
      region: Region.greaterAccra,
    ),
  ],
  Region.ashanti: const [
    Assembly(
      name: 'Kumasi',
      type: AssemblyType.metropolitan,
      region: Region.ashanti,
    ),
    Assembly(
      name: 'Obuasi',
      type: AssemblyType.municipal,
      region: Region.ashanti,
    ),
    Assembly(
      name: 'Ejisu',
      type: AssemblyType.municipal,
      region: Region.ashanti,
    ),
  ],
  Region.western: const [
    Assembly(
      name: 'Sekondi-Takoradi',
      type: AssemblyType.metropolitan,
      region: Region.western,
    ),
    Assembly(
      name: 'Ahanta West',
      type: AssemblyType.municipal,
      region: Region.western,
    ),
    Assembly(
      name: 'Tarkwa-Nsuaem',
      type: AssemblyType.municipal,
      region: Region.western,
    ),
  ],
  Region.westernNorth: const [
    Assembly(
      name: 'Sefwi Wiawso',
      type: AssemblyType.municipal,
      region: Region.westernNorth,
    ),
    Assembly(
      name: 'Bibiani Anhwiaso Bekwai',
      type: AssemblyType.municipal,
      region: Region.westernNorth,
    ),
    Assembly(
      name: 'Juaboso',
      type: AssemblyType.district,
      region: Region.westernNorth,
    ),
  ],
  Region.central: const [
    Assembly(
      name: 'Cape Coast',
      type: AssemblyType.metropolitan,
      region: Region.central,
    ),
    Assembly(
      name: 'Komenda-Edina-Eguafo-Abirem',
      type: AssemblyType.municipal,
      region: Region.central,
    ),
    Assembly(
      name: 'Awutu Senya East',
      type: AssemblyType.municipal,
      region: Region.central,
    ),
  ],
  Region.eastern: const [
    Assembly(
      name: 'New Juaben South',
      type: AssemblyType.municipal,
      region: Region.eastern,
    ),
    Assembly(
      name: 'Suhum',
      type: AssemblyType.municipal,
      region: Region.eastern,
    ),
    Assembly(
      name: 'Nsawam Adoagyiri',
      type: AssemblyType.municipal,
      region: Region.eastern,
    ),
  ],
  Region.volta: const [
    Assembly(name: 'Ho', type: AssemblyType.municipal, region: Region.volta),
    Assembly(name: 'Keta', type: AssemblyType.municipal, region: Region.volta),
    Assembly(
      name: 'Hohoe',
      type: AssemblyType.municipal,
      region: Region.volta,
    ),
  ],
  Region.oti: const [
    Assembly(
      name: 'Krachi East',
      type: AssemblyType.municipal,
      region: Region.oti,
    ),
    Assembly(
      name: 'Nkwanta South',
      type: AssemblyType.municipal,
      region: Region.oti,
    ),
    Assembly(name: 'Kadjebi', type: AssemblyType.district, region: Region.oti),
  ],
  Region.northern: const [
    Assembly(
      name: 'Tamale',
      type: AssemblyType.metropolitan,
      region: Region.northern,
    ),
    Assembly(
      name: 'Sagnarigu',
      type: AssemblyType.municipal,
      region: Region.northern,
    ),
    Assembly(
      name: 'Yendi',
      type: AssemblyType.municipal,
      region: Region.northern,
    ),
  ],
  Region.northEast: const [
    Assembly(
      name: 'East Mamprusi',
      type: AssemblyType.municipal,
      region: Region.northEast,
    ),
    Assembly(
      name: 'Bunkpurugu Nyakpanduri',
      type: AssemblyType.district,
      region: Region.northEast,
    ),
  ],
  Region.savannah: const [
    Assembly(
      name: 'West Gonja',
      type: AssemblyType.municipal,
      region: Region.savannah,
    ),
    Assembly(
      name: 'Bole',
      type: AssemblyType.district,
      region: Region.savannah,
    ),
  ],
  Region.upperEast: const [
    Assembly(
      name: 'Bolgatanga',
      type: AssemblyType.municipal,
      region: Region.upperEast,
    ),
    Assembly(
      name: 'Bawku',
      type: AssemblyType.municipal,
      region: Region.upperEast,
    ),
    Assembly(
      name: 'Kassena Nankana',
      type: AssemblyType.municipal,
      region: Region.upperEast,
    ),
  ],
  Region.upperWest: const [
    Assembly(
      name: 'Wa',
      type: AssemblyType.municipal,
      region: Region.upperWest,
    ),
    Assembly(
      name: 'Jirapa',
      type: AssemblyType.municipal,
      region: Region.upperWest,
    ),
    Assembly(
      name: 'Nadowli-Kaleo',
      type: AssemblyType.district,
      region: Region.upperWest,
    ),
  ],
  Region.bono: const [
    Assembly(
      name: 'Sunyani',
      type: AssemblyType.municipal,
      region: Region.bono,
    ),
    Assembly(
      name: 'Berekum East',
      type: AssemblyType.municipal,
      region: Region.bono,
    ),
    Assembly(
      name: 'Dormaa Central',
      type: AssemblyType.municipal,
      region: Region.bono,
    ),
  ],
  Region.bonoEast: const [
    Assembly(
      name: 'Techiman',
      type: AssemblyType.municipal,
      region: Region.bonoEast,
    ),
    Assembly(
      name: 'Kintampo North',
      type: AssemblyType.municipal,
      region: Region.bonoEast,
    ),
    Assembly(
      name: 'Nkoranza South',
      type: AssemblyType.municipal,
      region: Region.bonoEast,
    ),
  ],
  Region.ahafo: const [
    Assembly(
      name: 'Asunafo North',
      type: AssemblyType.municipal,
      region: Region.ahafo,
    ),
    Assembly(
      name: 'Asutifi North',
      type: AssemblyType.district,
      region: Region.ahafo,
    ),
  ],
};
