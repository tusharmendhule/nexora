import { ZodError } from "zod";

/**
 * Validate `req.body` against a zod schema. On failure, returns a 400 with a
 * readable message; on success, replaces req.body with the parsed (and thus
 * sanitized / coerced) value.
 */
export function validate(schema, { stripUnknown = true } = {}) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      if (result.error instanceof ZodError) {
        const first = result.error.issues[0];
        const path = first?.path?.length ? `${first.path.join(".")}: ` : "";
        return res.status(400).json({ error: `${path}${first?.message ?? "Invalid input"}` });
      }
      return res.status(400).json({ error: "Invalid input" });
    }
    req.body = result.data;
    next();
  };
}
