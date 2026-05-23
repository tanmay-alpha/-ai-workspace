// Simple assertion-based test without external dependencies
function assert(condition, message) {
  if (!condition) {
    throw new Error('FAIL: ' + message);
  }
  console.log('PASS:', message);
}

// Tests
assert(1 + 1 === 2, 'basic addition');
assert('hello'.toUpperCase() === 'HELLO', 'string toUpperCase');
assert([1, 2, 3].length === 3, 'array length');

console.log('All tests passed.');
