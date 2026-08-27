import 'package:flutter/material.dart';

class HomePreviewService {
  final String name;
  final IconData icon;
  final String searchQuery;

  const HomePreviewService({
    required this.name,
    required this.icon,
    required this.searchQuery,
  });
}

class HomeFeatureItem {
  final String number;
  final String title;
  final String description;
  final List<String> bullets;
  final IconData icon;

  const HomeFeatureItem({
    required this.number,
    required this.title,
    required this.description,
    required this.bullets,
    required this.icon,
  });
}

class HomeWhyItem {
  final String title;
  final IconData icon;

  const HomeWhyItem({required this.title, required this.icon});
}

class HomeContent {
  HomeContent._();

  static const String heroBadge = 'Premium beauty booking';
  static const String heroTitle = 'GLOWVAX';
  static const String heroSubtitle =
      'Discover trusted salons, spas, and beauty professionals near you. Book appointments effortlessly with a simple, secure, and convenient experience.';

  static const String servicesTitle = 'Premium Services Preview';
  static const String servicesSubtitle =
      'Choose the service you need and book with verified professionals in just a few taps.';

  static const String featuresTitle = 'Built for Seamless GLOWVAX Experiences';
  static const String featuresSubtitle =
      'Explore a premium booking experience designed to feel simple, secure, and elegant from the first search to the final confirmation.';

  static const List<HomePreviewService> previewServices = [
    HomePreviewService(
      name: 'Salon',
      icon: Icons.content_cut_rounded,
      searchQuery: 'salon',
    ),
    HomePreviewService(
      name: 'Spa',
      icon: Icons.spa_rounded,
      searchQuery: 'spa',
    ),
    HomePreviewService(
      name: 'Tattoo',
      icon: Icons.brush_rounded,
      searchQuery: 'tattoo',
    ),
    HomePreviewService(
      name: 'Beauty',
      icon: Icons.face_retouching_natural_rounded,
      searchQuery: 'beauty',
    ),
    HomePreviewService(
      name: 'Grooming',
      icon: Icons.self_improvement_rounded,
      searchQuery: 'grooming',
    ),
    HomePreviewService(
      name: 'Wellness',
      icon: Icons.favorite_rounded,
      searchQuery: 'wellness',
    ),
  ];

  static const List<HomeFeatureItem> features = [
    HomeFeatureItem(
      number: '01',
      title: 'Smart Discovery',
      description: 'Search by service, category, city, tags, nearby listings, featured partners, and top-rated professionals.',
      bullets: [
        'Nearby and featured discovery',
        'Autocomplete and filters',
        'Recent search history',
      ],
      icon: Icons.travel_explore_rounded,
    ),
    HomeFeatureItem(
      number: '02',
      title: 'Live Booking Flow',
      description: 'Check real-time slot availability, create bookings, reschedule visits, and track status end to end.',
      bullets: [
        'Available time slots',
        'Reschedule acceptance flow',
        'Upcoming and history tracking',
      ],
      icon: Icons.event_available_rounded,
    ),
    HomeFeatureItem(
      number: '03',
      title: 'Wallet & Secure Payments',
      description: 'Razorpay checkout, wallet top-ups, saved payment methods, refunds, invoices, and payment verification.',
      bullets: [
        'Wallet top-up and pay',
        'Refund and invoice support',
        'Razorpay verification',
      ],
      icon: Icons.account_balance_wallet_rounded,
    ),
    HomeFeatureItem(
      number: '04',
      title: 'Verified Partners',
      description: 'Businesses register, complete KYC approval, set availability, add galleries, and go live with confidence.',
      bullets: [
        'KYC approval workflow',
        'Availability and slots',
        'Portfolio image uploads',
      ],
      icon: Icons.verified_user_rounded,
    ),
    HomeFeatureItem(
      number: '05',
      title: 'Staff & Operations',
      description: 'Partners manage services, assign staff to bookings, track schedules, and view earnings.',
      bullets: [
        'Staff assignment',
        'Schedule and leave control',
        'Partner service pricing',
      ],
      icon: Icons.groups_rounded,
    ),
    HomeFeatureItem(
      number: '06',
      title: 'Reviews & Membership',
      description: 'Completed-booking reviews, real-time notifications, push messaging, and membership benefits.',
      bullets: [
        'Verified review rules',
        'Real-time alerts',
        'Membership plans and perks',
      ],
      icon: Icons.star_rounded,
    ),
  ];

  static const List<HomeWhyItem> whyItems = [
    HomeWhyItem(title: 'Verified Partner Salons', icon: Icons.verified_rounded),
    HomeWhyItem(title: 'Easy Online Booking', icon: Icons.touch_app_rounded),
    HomeWhyItem(title: 'Secure Payments', icon: Icons.lock_rounded),
    HomeWhyItem(title: 'Best Offers', icon: Icons.local_offer_rounded),
    HomeWhyItem(title: 'Instant Confirmation', icon: Icons.flash_on_rounded),
    HomeWhyItem(title: 'Trusted Experience', icon: Icons.shield_rounded),
  ];

  static const String whyTitle = 'Why GLOWVAX';
  static const String whySubtitle =
      'GLOWVAX helps you discover trusted beauty professionals and book appointments effortlessly. We make salon booking simple, secure, and convenient.';

  static const String partnerTitle = 'Partner With GLOWVAX';
  static const String partnerSubtitle =
      'Join GLOWVAX and grow your salon business. Reach more customers, manage appointments with ease, and increase your bookings through our platform.';
}
