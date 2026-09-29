// Browser-tier twin of favorite-index.blobl — a stub that throws, for the
// reason stated in favorite-recount.browser.js
// (ir decision-browser-tier-unsupported).
export default () => {
  throw new Error(
    "favorite-index: the browser tier is unsupported (ir decision-browser-tier-unsupported). This pipeline emits an array of favorite_index rows keyed <user_id>:<article_id>; the browser shim contract is (rows) => one row upserted on id. Run the container tier.",
  );
};
