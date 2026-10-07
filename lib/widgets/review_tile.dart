import 'package:ctadmobl_project/models/review.dart';
import 'package:flutter/material.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({required this.review, super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(Icons.star, size: 16, color: colors.primary),
              const SizedBox(width: 4),
              Text(review.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment),
          const SizedBox(height: 6),
          Text(
            MaterialLocalizations.of(context).formatShortDate(review.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
