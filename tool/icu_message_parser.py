"""Parse the ICU message subset used by the localization validators."""

from __future__ import annotations

import re
from typing import NamedTuple


IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
COMPLEX_ARGUMENT_TYPES = {"plural", "select", "selectordinal"}
SIMPLE_ARGUMENT_TYPES = {"date", "number", "time"}
PLURAL_CATEGORY_SELECTORS = {"zero", "one", "two", "few", "many", "other"}


class ArgumentUse(NamedTuple):
    name: str
    argument_type: str | None
    selectors: tuple[str, ...]


class IcuSyntaxError(ValueError):
    """Raised when a message does not follow the supported ICU grammar."""


class IcuMessageParser:
    def __init__(self, message: str) -> None:
        self.message = message
        self.position = 0
        self.arguments: list[ArgumentUse] = []

    def parse(self) -> list[ArgumentUse]:
        self._parse_message(expect_closing=False)
        return self.arguments

    def _parse_message(self, *, expect_closing: bool) -> None:
        while self.position < len(self.message):
            character = self.message[self.position]
            if character == "{":
                self._parse_argument()
                continue
            if character == "}":
                if not expect_closing:
                    raise IcuSyntaxError(
                        f"unexpected '}}' at offset {self.position}"
                    )
                self.position += 1
                return
            self.position += 1
        if expect_closing:
            raise IcuSyntaxError("missing closing '}'")

    def _parse_argument(self) -> None:
        self.position += 1
        self._skip_whitespace()
        name = self._read_identifier("argument name")
        self._skip_whitespace()
        if self._consume("}"):
            self.arguments.append(ArgumentUse(name, None, ()))
            return
        self._expect(",", "after argument name")
        self._skip_whitespace()
        argument_type = self._read_identifier("argument type")
        self._skip_whitespace()
        if argument_type not in COMPLEX_ARGUMENT_TYPES:
            if argument_type not in SIMPLE_ARGUMENT_TYPES:
                raise IcuSyntaxError(
                    f"unsupported argument type: {argument_type}"
                )
            self._parse_simple_argument_style()
            self.arguments.append(ArgumentUse(name, argument_type, ()))
            return
        self._expect(",", f"after {argument_type} argument type")
        selectors = self._parse_complex_cases(argument_type)
        self.arguments.append(ArgumentUse(name, argument_type, selectors))

    def _parse_simple_argument_style(self) -> None:
        if self._consume("}"):
            return
        self._expect(",", "before argument style")
        while self.position < len(self.message):
            character = self.message[self.position]
            if character == "{":
                raise IcuSyntaxError(
                    f"nested '{{' in simple argument at offset {self.position}"
                )
            if character == "}":
                self.position += 1
                return
            self.position += 1
        raise IcuSyntaxError("missing closing '}'")

    def _parse_complex_cases(self, argument_type: str) -> tuple[str, ...]:
        cases: set[str] = set()
        parsed_offset = False
        while True:
            self._skip_whitespace()
            if argument_type in {"plural", "selectordinal"} and self.message.startswith(
                "offset:", self.position
            ):
                if parsed_offset:
                    raise IcuSyntaxError(f"duplicate {argument_type} offset")
                parsed_offset = True
                self.position += len("offset:")
                self._skip_whitespace()
                self._read_number("plural offset")
                continue
            if self._consume("}"):
                break
            selector_start = self.position
            while (
                self.position < len(self.message)
                and not self.message[self.position].isspace()
                and self.message[self.position] not in "{}"
            ):
                self.position += 1
            selector = self.message[selector_start : self.position]
            if not selector:
                raise IcuSyntaxError(
                    f"missing {argument_type} selector at offset {self.position}"
                )
            if (
                argument_type in {"plural", "selectordinal"}
                and selector not in PLURAL_CATEGORY_SELECTORS
                and re.fullmatch(r"=[0-9]+", selector) is None
            ):
                raise IcuSyntaxError(
                    f"{argument_type} selector is invalid: {selector}"
                )
            if selector in cases:
                raise IcuSyntaxError(
                    f"duplicate {argument_type} selector: {selector}"
                )
            cases.add(selector)
            self._skip_whitespace()
            self._expect("{", f"after {argument_type} selector {selector}")
            self._parse_message(expect_closing=True)
        if "other" not in cases:
            raise IcuSyntaxError(
                f"{argument_type} argument is missing an other case"
            )
        return tuple(sorted(cases))

    def _read_identifier(self, label: str) -> str:
        match = IDENTIFIER.match(self.message, self.position)
        if match is None:
            raise IcuSyntaxError(f"missing {label} at offset {self.position}")
        self.position = match.end()
        return match.group(0)

    def _read_number(self, label: str) -> None:
        start = self.position
        if self.position < len(self.message) and self.message[self.position] in "+-":
            self.position += 1
        while (
            self.position < len(self.message)
            and self.message[self.position].isdigit()
        ):
            self.position += 1
        if self.position == start or (
            self.position == start + 1 and self.message[start] in "+-"
        ):
            raise IcuSyntaxError(f"missing {label} at offset {start}")

    def _skip_whitespace(self) -> None:
        while (
            self.position < len(self.message)
            and self.message[self.position].isspace()
        ):
            self.position += 1

    def _consume(self, expected: str) -> bool:
        if self.message.startswith(expected, self.position):
            self.position += len(expected)
            return True
        return False

    def _expect(self, expected: str, context: str) -> None:
        if not self._consume(expected):
            raise IcuSyntaxError(
                f"expected {expected!r} {context} at offset {self.position}"
            )
