import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/skin.dart';
import 'package:customer_app/state/store_state.dart';
import 'package:customer_app/theme.dart';

void main() {
  test('money formats with grouping', () {
    expect(money('৳', 1050), '৳1,050');
    expect(money('৳', 99.5), '৳99.50');
  });

  test('Bangla money and quantity labels match the website', () {
    expect(bnMoney('৳', 3450), '৳৩,৪৫০');
    final beef = {'sold_by_weight': true, 'unit': 'Kg'};
    expect(bnQty(0.5, beef), '৫০০ গ্রাম');
    expect(bnQty(1, beef), '১ কেজি');
    expect(bnQty(1.5, beef), '১.৫ কেজি');
    expect(bnQty(2, {'sold_by_weight': false, 'unit_bn': 'পিস'}), '২ পিস');
  });

  test('prices use the admin option price when the amount is an option, else unit × amount', () {
    final p = {
      'price': 850,
      'compare_price': 900,
      'options': [
        {'qty': 1, 'price': 850},
        {'qty': 2, 'price': 1650},
      ],
    };
    expect(StoreState.priceFor(p, 2), 1650);
    expect(StoreState.priceFor(p, 1.5), 1275);
    expect(StoreState.compareFor(p, 2), 1800);
    expect(StoreState.compareFor({'price': 900, 'compare_price': 900}, 1), 0);
  });
}
