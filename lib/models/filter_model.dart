import 'package:flutter/material.dart';

enum OfferRange {
  any,
  lessThan5,
  from5to10,
  from10to20,
  moreThan20,
}

enum HiringRate {
  any,
  moreThan0,
  moreThan50,
  moreThan75,
}

class JobFilters {
  OfferRange offerRange;
  HiringRate hiringRate;
  RangeValues budget;

  JobFilters({
    this.offerRange = OfferRange.any,
    this.hiringRate = HiringRate.any,
    this.budget = const RangeValues(0, 5000),
  });

  bool get isAnyFilterActive =>
      offerRange != OfferRange.any ||
      hiringRate != HiringRate.any ||
      budget.start != 0 ||
      budget.end != 5000;

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