// Browser-tier twin of favorite-count.blobl — a stub that throws
// (ir decision-browser-tier-unsupported). The shim contract is
// (rows) => one row upserted on `id`, and this pipeline emits a row keyed on
// the (reader, article) pair, which that contract cannot state.
export default () => {
  throw new Error(
    "favorite-count: the browser tier is unsupported (ir decision-browser-tier-unsupported). This pipeline emits a row keyed on the reader/article pair; the browser shim contract is (rows) => one row upserted on id. Run the container tier.",
  );
};
