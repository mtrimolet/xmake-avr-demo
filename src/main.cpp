#include <avr/io.h>
#include <util/delay.h>

auto main(void) noexcept -> int {
  DDRB |= (1 << DDB7);
  
  for (;;) {
    PORTB |= (1 << PB7);
    _delay_ms(500);
    PORTB &= ~(1 << PB7);
    _delay_ms(500);
  }
  return 0;
}
