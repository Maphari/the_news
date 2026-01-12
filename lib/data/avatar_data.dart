import 'package:the_news/model/avatar_model.dart';

//? Define avatar positions and sizes with news brand logos
//? Using Google's Favicon service for better reliability
final List<AvatarData> avatars = [
    //? Large avatars - Major news brands
    AvatarData(
      left: 0.15,
      top: 0.01,
      size: 90,
      imageUrl: getLogoUrl('cnn.com'),
      brandName: 'CNN',
    ),
    AvatarData(
      left: 0.65,
      top: 0.15,
      size: 85,
      imageUrl: getLogoUrl('bbc.com'),
      brandName: 'BBC',
    ),
    AvatarData(
      left: 0.05,
      top: 0.28,
      size: 85,
      imageUrl: getLogoUrl('nytimes.com'),
      brandName: 'NYT',
    ),

    //? Medium avatars
    AvatarData(
      left: 0.45,
      top: 0.08,
      size: 70,
      imageUrl: getLogoUrl('reuters.com'),
      brandName: 'Reuters',
    ),
    AvatarData(
      left: 0.25,
      top: 0.18,
      size: 65,
      imageUrl: getLogoUrl('theguardian.com'),
      brandName: 'Guardian',
    ),
    AvatarData(
      left: 0.75,
      top: 0.05,
      size: 60,
      imageUrl: getLogoUrl('forbes.com'),
      brandName: 'Forbes',
    ),
    AvatarData(
      left: 0.50,
      top: 0.30,
      size: 68,
      imageUrl: getLogoUrl('wsj.com'),
      brandName: 'WSJ',
    ),
    AvatarData(
      left: 0.90,
      top: 0.24,
      size: 82,
      imageUrl: getLogoUrl('bloomberg.com'),
      brandName: 'Bloomberg',
    ),

    //? Small avatars
    AvatarData(
      left: 0.08,
      top: 0.12,
      size: 55,
      imageUrl: getLogoUrl('techcrunch.com'),
      brandName: 'TC',
    ),
    AvatarData(
      left: 0.35,
      top: 0.01,
      size: 65,
      imageUrl: getLogoUrl('aljazeera.com'),
      brandName: 'AJ',
    ),
    AvatarData(
      left: 0.88,
      top: 0.12,
      size: 98,
      imageUrl: getLogoUrl('time.com'),
      brandName: 'Time',
    ),
    AvatarData(
      left: 0.10,
      top: 0.20,
      size: 72,
      imageUrl: getLogoUrl('politico.com'),
      brandName: 'Politico',
    ),
    AvatarData(
      left: 0.68,
      top: 0.25,
      size: 76,
      imageUrl: getLogoUrl('axios.com'),
      brandName: 'Axios',
    ),
    AvatarData(
      left: 0.38,
      top: 0.22,
      size: 84,
      imageUrl: getLogoUrl('npr.org'),
      brandName: 'NPR',
    ),

    //? Extra small avatars
    AvatarData(
      left: 0.30,
      top: 0.10,
      size: 75,
      imageUrl: getLogoUrl('apnews.com'),
      brandName: 'AP',
    ),
    AvatarData(
      left: 0.92,
      top: 0.03,
      size: 80,
      imageUrl: getLogoUrl('ft.com'),
      brandName: 'FT',
    ),
    AvatarData(
      left: 0.48,
      top: 0.15,
      size: 68,
      imageUrl: getLogoUrl('economist.com'),
      brandName: 'Economist',
    ),
    AvatarData(
      left: 0.27,
      top: 0.30,
      size: 76,
      imageUrl: getLogoUrl('cnbc.com'),
      brandName: 'CNBC',
    ),
    AvatarData(
      left: 0.95,
      top: 0.52,
      size: 64,
      imageUrl: getLogoUrl('washingtonpost.com'),
      brandName: 'WP',
    ),
    AvatarData(
      left: 0.58,
      top: 0.01,
      size: 80,
      imageUrl: getLogoUrl('theatlantic.com'),
      brandName: 'Atlantic',
    ),
  ];

  String getLogoUrl(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }