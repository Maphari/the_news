import 'package:flutter/material.dart';

/// Localizations for the app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'explore': 'Explore',
      'library': 'Library',
      'profile': 'Profile',

      // Common
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'done': 'Done',
      'back': 'Back',
      'next': 'Next',
      'skip': 'Skip',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',

      // Home
      'featured_news': 'Featured News',
      'latest_news': 'Latest News',
      'trending': 'Trending',
      'for_you': 'For You',

      // Articles
      'read_more': 'Read More',
      'reading_time': 'min read',
      'source': 'Source',
      'published': 'Published',
      'share': 'Share',
      'save_for_later': 'Save for Later',
      'download_offline': 'Download for Offline',

      // Daily Digest
      'daily_digest': 'Daily Digest',
      'generate_digest': 'Generate Digest',
      'your_digest': 'Your Digest',
      'digest_ready': 'Your digest is ready',
      'stories': 'stories',
      'listen': 'Listen',
      'share_digest': 'Share Digest',

      // Settings
      'settings': 'Settings',
      'preferences': 'Preferences',
      'notifications': 'Notifications',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system_default': 'System Default',

      // Reading Preferences
      'reading_preferences': 'Reading Preferences',
      'font_size': 'Font Size',
      'font_family': 'Font Family',
      'line_spacing': 'Line Spacing',
      'reading_theme': 'Reading Theme',

      // Analytics
      'analytics': 'Analytics',
      'reading_analytics': 'Reading Analytics',
      'articles_read': 'Articles Read',
      'reading_streak': 'Reading Streak',
      'current_streak': 'Current',
      'longest_streak': 'Longest',
      'category_breakdown': 'Category Breakdown',
      'top_sources': 'Top Sources',

      // Offline
      'offline_reading': 'Offline Reading',
      'downloaded_articles': 'Downloaded Articles',
      'storage': 'Storage',
      'clear_cache': 'Clear Cache',
      'auto_download': 'Auto Download on WiFi',

      // AI Integration
      'ai_integration': 'AI Integration',
      'ai_settings': 'AI Settings',
      'ai_provider': 'AI Provider',
      'api_key': 'API Key',
      'configure_ai': 'Configure AI',

      // Multi-Perspective
      'multi_perspective': 'Multi-Perspective',
      'perspectives': 'Perspectives',
      'view_all_perspectives': 'View All Perspectives',
      'compare_perspectives': 'Compare Perspectives',
      'bias_indicator': 'Bias Indicator',
      'source_credibility': 'Source Credibility',

      // Notes & Highlights
      'notes_highlights': 'Notes & Highlights',
      'add_note': 'Add Note',
      'highlight': 'Highlight',
      'my_highlights': 'My Highlights',
      'export': 'Export',

      // Errors
      'error_loading': 'Error loading data',
      'error_network': 'Network error. Please check your connection.',
      'error_generic': 'Something went wrong. Please try again.',
      'no_articles': 'No articles found',
      'no_data': 'No data available',
    },
    'es': {
      // Navigation
      'home': 'Inicio',
      'explore': 'Explorar',
      'library': 'Biblioteca',
      'profile': 'Perfil',

      // Common
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'done': 'Hecho',
      'back': 'Atrás',
      'next': 'Siguiente',
      'skip': 'Saltar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'retry': 'Reintentar',

      // Home
      'featured_news': 'Noticias Destacadas',
      'latest_news': 'Últimas Noticias',
      'trending': 'Tendencias',
      'for_you': 'Para Ti',

      // Articles
      'read_more': 'Leer Más',
      'reading_time': 'min de lectura',
      'source': 'Fuente',
      'published': 'Publicado',
      'share': 'Compartir',
      'save_for_later': 'Guardar para Después',
      'download_offline': 'Descargar sin Conexión',

      // Daily Digest
      'daily_digest': 'Resumen Diario',
      'generate_digest': 'Generar Resumen',
      'your_digest': 'Tu Resumen',
      'digest_ready': 'Tu resumen está listo',
      'stories': 'historias',
      'listen': 'Escuchar',
      'share_digest': 'Compartir Resumen',

      // Settings
      'settings': 'Configuración',
      'preferences': 'Preferencias',
      'notifications': 'Notificaciones',
      'language': 'Idioma',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'system_default': 'Por Defecto del Sistema',

      // Reading Preferences
      'reading_preferences': 'Preferencias de Lectura',
      'font_size': 'Tamaño de Fuente',
      'font_family': 'Tipo de Fuente',
      'line_spacing': 'Espaciado de Línea',
      'reading_theme': 'Tema de Lectura',

      // Analytics
      'analytics': 'Análisis',
      'reading_analytics': 'Análisis de Lectura',
      'articles_read': 'Artículos Leídos',
      'reading_streak': 'Racha de Lectura',
      'current_streak': 'Actual',
      'longest_streak': 'Más Larga',
      'category_breakdown': 'Desglose por Categoría',
      'top_sources': 'Principales Fuentes',

      // Offline
      'offline_reading': 'Lectura sin Conexión',
      'downloaded_articles': 'Artículos Descargados',
      'storage': 'Almacenamiento',
      'clear_cache': 'Limpiar Caché',
      'auto_download': 'Descarga Automática con WiFi',

      // AI Integration
      'ai_integration': 'Integración de IA',
      'ai_settings': 'Configuración de IA',
      'ai_provider': 'Proveedor de IA',
      'api_key': 'Clave API',
      'configure_ai': 'Configurar IA',

      // Multi-Perspective
      'multi_perspective': 'Multi-Perspectiva',
      'perspectives': 'Perspectivas',
      'view_all_perspectives': 'Ver Todas las Perspectivas',
      'compare_perspectives': 'Comparar Perspectivas',
      'bias_indicator': 'Indicador de Sesgo',
      'source_credibility': 'Credibilidad de la Fuente',

      // Notes & Highlights
      'notes_highlights': 'Notas y Resaltados',
      'add_note': 'Añadir Nota',
      'highlight': 'Resaltar',
      'my_highlights': 'Mis Resaltados',
      'export': 'Exportar',

      // Errors
      'error_loading': 'Error al cargar datos',
      'error_network': 'Error de red. Por favor verifica tu conexión.',
      'error_generic': 'Algo salió mal. Por favor inténtalo de nuevo.',
      'no_articles': 'No se encontraron artículos',
      'no_data': 'No hay datos disponibles',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'explore': 'Explorer',
      'library': 'Bibliothèque',
      'profile': 'Profil',

      // Common
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'done': 'Terminé',
      'back': 'Retour',
      'next': 'Suivant',
      'skip': 'Passer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'retry': 'Réessayer',

      // Home
      'featured_news': 'Actualités en Vedette',
      'latest_news': 'Dernières Nouvelles',
      'trending': 'Tendances',
      'for_you': 'Pour Vous',

      // Articles
      'read_more': 'Lire Plus',
      'reading_time': 'min de lecture',
      'source': 'Source',
      'published': 'Publié',
      'share': 'Partager',
      'save_for_later': 'Enregistrer pour Plus Tard',
      'download_offline': 'Télécharger Hors Ligne',

      // Daily Digest
      'daily_digest': 'Résumé Quotidien',
      'generate_digest': 'Générer le Résumé',
      'your_digest': 'Votre Résumé',
      'digest_ready': 'Votre résumé est prêt',
      'stories': 'histoires',
      'listen': 'Écouter',
      'share_digest': 'Partager le Résumé',

      // Settings
      'settings': 'Paramètres',
      'preferences': 'Préférences',
      'notifications': 'Notifications',
      'language': 'Langue',
      'theme': 'Thème',
      'dark_mode': 'Mode Sombre',
      'light_mode': 'Mode Clair',
      'system_default': 'Par Défaut du Système',

      // Reading Preferences
      'reading_preferences': 'Préférences de Lecture',
      'font_size': 'Taille de Police',
      'font_family': 'Famille de Police',
      'line_spacing': 'Espacement des Lignes',
      'reading_theme': 'Thème de Lecture',

      // Analytics
      'analytics': 'Analytique',
      'reading_analytics': 'Analytique de Lecture',
      'articles_read': 'Articles Lus',
      'reading_streak': 'Série de Lecture',
      'current_streak': 'Actuelle',
      'longest_streak': 'Plus Longue',
      'category_breakdown': 'Répartition par Catégorie',
      'top_sources': 'Principales Sources',

      // Offline
      'offline_reading': 'Lecture Hors Ligne',
      'downloaded_articles': 'Articles Téléchargés',
      'storage': 'Stockage',
      'clear_cache': 'Vider le Cache',
      'auto_download': 'Téléchargement Auto sur WiFi',

      // AI Integration
      'ai_integration': 'Intégration IA',
      'ai_settings': 'Paramètres IA',
      'ai_provider': 'Fournisseur IA',
      'api_key': 'Clé API',
      'configure_ai': 'Configurer IA',

      // Multi-Perspective
      'multi_perspective': 'Multi-Perspective',
      'perspectives': 'Perspectives',
      'view_all_perspectives': 'Voir Toutes les Perspectives',
      'compare_perspectives': 'Comparer les Perspectives',
      'bias_indicator': 'Indicateur de Biais',
      'source_credibility': 'Crédibilité de la Source',

      // Notes & Highlights
      'notes_highlights': 'Notes et Surlignages',
      'add_note': 'Ajouter une Note',
      'highlight': 'Surligner',
      'my_highlights': 'Mes Surlignages',
      'export': 'Exporter',

      // Errors
      'error_loading': 'Erreur de chargement des données',
      'error_network': 'Erreur réseau. Veuillez vérifier votre connexion.',
      'error_generic': 'Quelque chose s\'est mal passé. Veuillez réessayer.',
      'no_articles': 'Aucun article trouvé',
      'no_data': 'Aucune donnée disponible',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get home => translate('home');
  String get explore => translate('explore');
  String get library => translate('library');
  String get profile => translate('profile');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get settings => translate('settings');
  String get dailyDigest => translate('daily_digest');
  String get readingAnalytics => translate('reading_analytics');
  String get offlineReading => translate('offline_reading');
  String get aiIntegration => translate('ai_integration');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'de', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
