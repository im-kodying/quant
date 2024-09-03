# Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

from cpython.object cimport PyObject
from libc.stdint cimport uint8_t, uint64_t, uintptr_t

from nautilus_trader.core.rust.core cimport CVec, UUID4_t
from nautilus_trader.core.rust.model cimport (InstrumentId_t, Price_t,
                                              Symbol_t, Venue_t)


cdef extern from "../includes/algorithms.h":

    # Represents a synthetic instrument with prices derived from component instruments using a
    # formula.
    cdef struct SyntheticInstrument:
        pass

    # Provides a C compatible Foreign Function Interface (FFI) for an underlying
    # [`SyntheticInstrument`].
    #
    # This struct wraps `SyntheticInstrument` in a way that makes it compatible with C function
    # calls, enabling interaction with `SyntheticInstrument` in a C environment.
    #
    # It implements the `Deref` trait, allowing instances of `SyntheticInstrument_API` to be
    # dereferenced to `SyntheticInstrument`, providing access to `SyntheticInstruments`'s methods without
    # having to manually access the underlying instance.
    cdef struct SyntheticInstrument_API:
        SyntheticInstrument *_0;

    # # Safety
    #
    # - Assumes `components_ptr` is a valid C string pointer of a JSON format list of strings.
    # - Assumes `formula_ptr` is a valid C string pointer.
    SyntheticInstrument_API synthetic_instrument_new(Symbol_t symbol,
                                                     uint8_t precision,
                                                     const char *components_ptr,
                                                     const char *formula_ptr);

    void synthetic_instrument_drop(SyntheticInstrument_API synth);

    InstrumentId_t synthetic_instrument_id(const SyntheticInstrument_API *synth);

    uint8_t synthetic_instrument_precision(const SyntheticInstrument_API *synth);

    const char *synthetic_instrument_formula_to_cstr(const SyntheticInstrument_API *synth);

    const char *synthetic_instrument_components_to_cstr(const SyntheticInstrument_API *synth);

    # # Safety
    #
    # - Assumes `formula_ptr` is a valid C string pointer.
    uint8_t synthetic_instrument_is_valid_formula(const SyntheticInstrument_API *synth,
                                                  const char *formula_ptr);

    # # Safety
    #
    # - Assumes `formula_ptr` is a valid C string pointer.
    void synthetic_instrument_change_formula(SyntheticInstrument_API *synth,
                                             const char *formula_ptr);

    Price_t synthetic_instrument_calculate(SyntheticInstrument_API *synth, const CVec *inputs_ptr);
