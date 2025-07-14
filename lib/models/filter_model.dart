// lib/models/filter_model.dart

import 'package:flutter/material.dart';

enum OfferRange { any, lessThan5, from5to10, from10to20, moreThan20 }

enum HiringRate { any, moreThan0, moreThan50, moreThan75 }

class JobFilters {
  OfferRange offerRange;
  HiringRate hiringRate;
  RangeValues budget;

  // A flag to check if advanced filters (requiring detail scraping) are active.
  bool get areAdvancedFiltersActive =>
      hiringRate != HiringRate.any ||
      budget.start != 0 ||
      budget.end != 5000;

  JobFilters({
    this.offerRange = OfferRange.any,
    this.hiringRate = HiringRate.any,
    this.budget = const RangeValues(0, 1500),
  });

  bool get isAnyFilterActive =>
      offerRange != OfferRange.any || areAdvancedFiltersActive;

  JobFilters copyWith({
    OfferRange? offerRange,
    HiringRate? hiringRate,
    RangeValues? budget,
  }) {
    return JobFilters(
      offerRange: offerRange ?? this.offerRange,
      hiringRate: hiringRate ?? this.hiringRate,
      budget: budget ?? this.budget,
    );
  }
}