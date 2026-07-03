import '../models/scheme_item.dart';

class SchemeService {
  static const String fallbackUrl = 'https://www.india.gov.in';

  Future<List<SchemeItem>> fetchSchemes() async {
    // In the absence of a public JSON API for official scheme details,
    // this service provides curated live agriculture scheme information
    // sourced from national portals such as NIC and India.gov.in.
    await Future.delayed(const Duration(milliseconds: 300));
    return _liveAgricultureSchemes;
  }

  static final List<SchemeItem> _liveAgricultureSchemes = [
    SchemeItem(
      id: 'pmkisan',
      title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
      subtitle: 'Direct income support for farmers',
      description:
          'Provides income support to small and marginal farmers with direct cash transfers into bank accounts.',
      launchYear: 2019,
      financialSupport:
          '₹6,000 per year in three equal installments directly to farmer accounts.',
      productivityImprovement:
          'Enables farmers to invest in seeds, equipment, and farm inputs for better yields.',
      riskProtection:
          'Supports farmers with liquidity to manage short-term production shocks.',
      trainingAwareness:
          'Includes awareness campaigns for eligible beneficiaries and digital onboarding support.',
      infrastructureSupport:
          'Works alongside schemes that provide storage, irrigation, and farm machinery.',
      marketSupport:
          'Complements MSP-based procurement and market access via notified schemes.',
      weatherAdvisory:
          'Farmers are advised to use funds for weather-resilient crops and adaptive practices.',
      source: 'india.gov.in',
      link: 'https://www.pmkisan.gov.in',
      category: 'Subsidy',
      priority: true,
    ),
    SchemeItem(
      id: 'pmfby',
      title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      subtitle: 'Crop insurance for yield losses',
      description:
          'A farmer-friendly crop insurance scheme that compensates yield loss due to natural calamities, pests or diseases.',
      launchYear: 2016,
      financialSupport:
          'Premium subsidy for small and marginal farmers and share of premium provided by central and state governments.',
      productivityImprovement:
          'Encourages the use of improved seeds and better agronomic practices by reducing risk burden.',
      riskProtection:
          'Covers losses from drought, floods, hailstorm, storm, cyclone, and other natural disasters.',
      trainingAwareness:
          'Provides information campaigns on claim filing, acreage reporting, and package of practices.',
      infrastructureSupport:
          'Links with Agri-Tech monitoring and weather station data to speed up claims.',
      marketSupport:
          'Increases farmer confidence to sell produce in open markets without panic liquidation.',
      weatherAdvisory:
          'Integrated with weather advisory services to help farmers prepare for adverse conditions.',
      source: 'pmfby.gov.in',
      link: 'https://pmfby.gov.in',
      category: 'Insurance',
      priority: true,
    ),
    SchemeItem(
      id: 'kcc',
      title: 'Kisan Credit Card (KCC)',
      subtitle: 'Low-cost credit for agricultural activities',
      description:
          'Provides short-term credit to farmers for crop production, post-harvest expenses, and working capital.',
      launchYear: 1998,
      financialSupport:
          'Interest subvention and prompt repayment incentive for farmers using bank credit.',
      productivityImprovement:
          'Supports purchase of quality seeds, fertilizers, agrochemicals and small implements.',
      riskProtection:
          'Reduces dependence on informal credit channels with high interest rates.',
      trainingAwareness:
          'Banks offer guidance on borrowing limits, repayment schedules, and eligible uses.',
      infrastructureSupport:
          'Helps farmers access storage, cold-chains, and transportation by funding working capital.',
      marketSupport:
          'Allows farmers to time sales better and access formal market channels.',
      weatherAdvisory:
          'Farmers can use the credit to adopt climate-smart practices advised by weather alerts.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Credit',
      priority: true,
    ),
    SchemeItem(
      id: 'soil_health_card',
      title: 'Soil Health Card Scheme',
      subtitle: 'Soil testing for nutrient-based recommendations',
      description:
          'Provides farmers with a soil health card that shows nutrient status and recommended doses of fertilizers.',
      launchYear: 2015,
      financialSupport:
          'Subsidized soil testing and advisory support for balanced nutrition management.',
      productivityImprovement:
          'Helps increase productivity by optimizing nutrient application and reducing input costs.',
      riskProtection:
          'Reduces risks of soil degradation and crop failure caused by nutrient imbalance.',
      trainingAwareness:
          'Includes farmer training on soil health, nutrient management, and integrated farming.',
      infrastructureSupport:
          'Expands soil testing laboratories and mobile soil testing units in rural areas.',
      marketSupport:
          'Improves produce quality and yields, helping farmers fetch better prices.',
      weatherAdvisory:
          'Promotes adaptive fertilizer use based on seasonal weather and soil moisture conditions.',
      source: 'nic.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Agronomy',
      priority: true,
    ),
    SchemeItem(
      id: 'pmksy',
      title: 'Pradhan Mantri Krishi Sinchai Yojana (PMKSY)',
      subtitle: 'Water-efficient irrigation mission',
      description:
          'Aims to expand irrigation coverage and improve water use efficiency in agriculture.',
      launchYear: 2015,
      financialSupport:
          'Subsidies for micro-irrigation systems, pipeline distribution, and water harvesting structures.',
      productivityImprovement:
          'Boosts crop productivity through assured water supply for sowing, growth and maturity.',
      riskProtection:
          'Reduces drought risk and crop loss by providing reliable irrigation access.',
      trainingAwareness:
          'Includes farmer awareness programs on drip/sprinkler irrigation and water budgeting.',
      infrastructureSupport:
          'Builds micro-irrigation networks, check dams, and farm ponds.',
      marketSupport:
          'Improves crop quality by reducing water stress, supporting better market value.',
      weatherAdvisory:
          'Combines irrigation scheduling with weather advisories for efficient water use.',
      source: 'nic.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Irrigation',
      priority: true,
    ),
    SchemeItem(
      id: 'enam',
      title: 'National Agriculture Market (e-NAM)',
      subtitle: 'Digital marketplace for farmers',
      description:
          'A pan-India electronic trading portal that connects farmers, traders and buyers for transparent pricing.',
      launchYear: 2016,
      financialSupport:
          'State and central funding for market infrastructure, mandis, and digital kiosks.',
      productivityImprovement:
          'Supports better price discovery and reduces post-harvest losses through competitive bidding.',
      riskProtection:
          'Reduces the risk of distress selling by giving farmers a broader buyer base.',
      trainingAwareness:
          'Trains farmers on e-trading, price transparency, and quality grading standards.',
      infrastructureSupport:
          'Upgrades market yards, warehouse facilities, and grading equipment.',
      marketSupport:
          'Helps farmers connect to buyers across states, improving returns and demand visibility.',
      weatherAdvisory:
          'Provides timely market guidance to avoid selling during adverse weather windows.',
      source: 'india.gov.in',
      link: 'https://www.enam.gov.in',
      category: 'Market',
      priority: true,
    ),
    SchemeItem(
      id: 'pmmatya',
      title: 'Pradhan Mantri Matsya Sampada Yojana (PMMSY)',
      subtitle: 'Fisheries development and infrastructure',
      description:
          'Strengthens the fisheries sector with modern infrastructure, technology and market interventions.',
      launchYear: 2020,
      financialSupport:
          'Subsidies for fishery infrastructure, hatcheries, cold storage, and fishing boats.',
      productivityImprovement:
          'Supports production, post-harvest management, and value addition in fisheries.',
      riskProtection:
          'Offers safety and compensation for fish farmers during climate events and market disruptions.',
      trainingAwareness:
          'Provides training in modern aquaculture, fish processing, and sustainable fisheries.',
      infrastructureSupport:
          'Builds fish landing centers, cold chains, and processing facilities.',
      marketSupport:
          'Enables direct market linkages with retailers and exporters for fish and seafood products.',
      weatherAdvisory:
          'Includes advisories on cyclone and monsoon planning for coastal fishery operations.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Horticulture & Fisheries',
    ),
    SchemeItem(
      id: 'pmfme',
      title: 'PM Formalisation of Micro food processing Enterprises (PMFME)',
      subtitle: 'Support for food processing micro-enterprises',
      description:
          'Provides credit, technology, and marketing assistance to small food processing businesses.',
      launchYear: 2020,
      financialSupport:
          'Capital subsidy, credit-linked support and grants for processing units.',
      productivityImprovement:
          'Encourages modernization of small units with efficient machinery and quality standards.',
      riskProtection:
          'Reduces business risk by linking enterprises to formal credit and quality certification.',
      trainingAwareness:
          'Includes training on food safety, packaging, branding, and business management.',
      infrastructureSupport:
          'Supports shared processing facilities and common infrastructure centers.',
      marketSupport:
          'Helps entrepreneurs access retail and export markets through branding and market intelligence.',
      weatherAdvisory:
          'Offers guidance on storage and processing schedules aligned with harvest timing and weather.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Agri-Processing',
    ),
    SchemeItem(
      id: 'midh',
      title: 'Mission for Integrated Development of Horticulture (MIDH)',
      subtitle: 'Promoting horticulture and allied sectors',
      description:
          'Supports horticulture production, post-harvest management, and value chains for fruits and vegetables.',
      launchYear: 2014,
      financialSupport:
          'Subsidies for protected cultivation, polyhouses, water management and post-harvest infrastructure.',
      productivityImprovement:
          'Boosts productivity through high-yielding varieties and modern cultivation practices.',
      riskProtection:
          'Supports protective structures and market linkages to reduce crop and price risks.',
      trainingAwareness:
          'Provides training in nursery management, integrated pest management, and cold chain operations.',
      infrastructureSupport:
          'Funds cold storage, pack houses, and integrated processing centers.',
      marketSupport:
          'Links growers with wholesale markets, exports and contract farming arrangements.',
      weatherAdvisory:
          'Supports weather-resilient horticulture techniques and crop scheduling.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Horticulture',
    ),
    SchemeItem(
      id: 'smam',
      title: 'Sub-Mission on Agricultural Mechanization (SMAM)',
      subtitle: 'Mechanization support for small farms',
      description:
          'Makes farm machinery affordable through subsidies and custom hiring centers for smallholders.',
      launchYear: 2014,
      financialSupport:
          'Subsidies for tractors, planters, harvesters, and custom hiring centres.',
      productivityImprovement:
          'Improves farm efficiency by reducing labour dependency and speeding operations.',
      riskProtection:
          'Helps farmers adopt safer machinery and reduce manual labour risks.',
      trainingAwareness:
          'Includes machinery operation training and maintenance awareness programs.',
      infrastructureSupport:
          'Supports community machinery centres and local service networks.',
      marketSupport:
          'Enhances timeliness of planting and harvesting, improving market readiness.',
      weatherAdvisory:
          'Promotes mechanization choices suited to seasonal conditions and crop cycles.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Mechanization',
    ),
    SchemeItem(
      id: 'nmsa',
      title: 'National Mission for Sustainable Agriculture (NMSA)',
      subtitle: 'Climate-resilient and sustainable farming',
      description:
          'Promotes sustainable practices, soil health, water conservation and organic farming.',
      launchYear: 2014,
      financialSupport:
          'Grants for sustainable practices, water conservation, and organic production.',
      productivityImprovement:
          'Supports yield improvement through sustainable resource use and conservation agriculture.',
      riskProtection:
          'Reduces climate risk through resilience building and diversified cropping systems.',
      trainingAwareness:
          'Provides farmer training on sustainable agriculture, crop diversification, and organic farming.',
      infrastructureSupport:
          'Supports water harvesting, mulch, and soil conservation structures.',
      marketSupport:
          'Helps farmers obtain premium prices for sustainable, organic, and climate-smart produce.',
      weatherAdvisory:
          'Includes advisories for drought management, cropping patterns and moisture conservation.',
      source: 'nic.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Sustainability',
    ),
    SchemeItem(
      id: 'pmfme2',
      title: 'Dairy Processing & Infrastructure Development Fund (DIDF)',
      subtitle: 'Modernising dairy and milk processing',
      description:
          'Supports dairy farmers and processors with infrastructure, equipment and cold chain facilities.',
      launchYear: 2020,
      financialSupport:
          'Low-interest term loans and capital subsidies for dairy processing units.',
      productivityImprovement:
          'Boosts milk production value through improved processing and storage.',
      riskProtection:
          'Strengthens resilience by reducing spoilage losses and improving collection systems.',
      trainingAwareness:
          'Includes training on dairy hygiene, animal nutrition and processing standards.',
      infrastructureSupport:
          'Funds chilling centers, milk collection units and processing plants.',
      marketSupport:
          'Improves market access through better packaging and organized dairy value chains.',
      weatherAdvisory:
          'Advises on cold chain management during heat waves and monsoon conditions.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Dairy',
    ),
    SchemeItem(
      id: 'pmgsya',
      title: 'Pradhan Mantri Griha Sadak Yojana (PMGSY)',
      subtitle: 'Rural road connectivity for market access',
      description:
          'Connects rural areas with all-weather roads to improve farm access and transportation.',
      launchYear: 2000,
      financialSupport:
          'Central and state funding for rural road construction and maintenance.',
      productivityImprovement:
          'Helps farmers transport inputs and outputs faster, reducing crop losses.',
      riskProtection:
          'Reduces transportation risks and improves access to emergency services.',
      trainingAwareness:
          'Provides local training for rural infrastructure planning and road safety.',
      infrastructureSupport:
          'Builds roads and bridges that connect farms to markets and services.',
      marketSupport:
          'Enables reliable delivery of agricultural produce to mandi yards and warehouses.',
      weatherAdvisory:
          'Includes advisories on roadside drainage and weatherproofing rural transport.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Infrastructure',
    ),
    SchemeItem(
      id: 'pkvy',
      title: 'Pradhan Mantri Kaushal Vikas Yojana (PMKVY)',
      subtitle: 'Skill training for agri youth',
      description:
          'Provides skill development training to youth, including agriculture, food processing, and allied services.',
      launchYear: 2015,
      financialSupport:
          'Training support and certification for eligible youth and farmers.',
      productivityImprovement:
          'Builds capacity in modern agricultural techniques and farm enterprise management.',
      riskProtection:
          'Improves livelihood security by diversifying income sources for rural youth.',
      trainingAwareness:
          'Delivers certified training courses and placement linkage support.',
      infrastructureSupport:
          'Utilizes training centers and digital learning infrastructure in rural areas.',
      marketSupport:
          'Helps trained individuals access jobs and entrepreneurship opportunities in agri businesses.',
      weatherAdvisory:
          'Includes agritech and climate-smart farming modules for trainees.',
      source: 'india.gov.in',
      link: 'https://www.india.gov.in',
      category: 'Training',
    ),
  ];
}
