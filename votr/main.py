from flask import Flask, render_template, request, Response, redirect, url_for
import sqlalchemy

from werkzeug.exceptions import abort

from . import sql

# This global variable is declared with a value of `None`, instead of calling
# `init_connection_engine()` immediately, to simplify testing. In general, it
# is safe to initialize your database connection pool when your script starts
# -- there is no need to wait for the first request.
db = None

app = Flask(__name__)

@app.before_first_request
def create_tables():
    global db
    db = db or sql.init_connection_engine()
    # Create tables (if they don't already exist)
    with db.connect() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS polls "
            "(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
            "question VARCHAR(100) NOT NULL, answer1 VARCHAR(100) NOT NULL, votes1 INT NOT NULL, answer2 VARCHAR(100) NOT NULL, "
            "votes2 INT NOT NULL, answer3 VARCHAR(100), votes3 INT, answer4 VARCHAR(100), votes4 INT );"
        )

@app.route('/')
def index():
    with db.connect() as conn:
        polls = conn.execute(
            'SELECT id, created, question'
            ' FROM polls p'
            ' ORDER BY created DESC'
        ).fetchall()
        return render_template('polls.html', polls=polls)

@app.route('/create', methods=['GET','POST'])
def create():
    if request.method == 'POST':
        question = request.form['question']
        answer1 = request.form['answer1']
        answer2 = request.form['answer2']
        answer3 = request.form['answer3']
        answer4 = request.form['answer4']
        error = None

        if not question:
            error = 'Question is required.'
        
        if error is not None:
            abort(404)
        else:
            stmt = sqlalchemy.text(
                "INSERT INTO polls (question, answer1, answer2, answer3, answer4, votes1, votes2, votes3, votes4) "
                "VALUES (:q, :a1, :a2, :a3, :a4, 0, 0, 0, 0)"
            )
            with db.connect() as conn:
                conn.execute(
                    stmt,
                    q=question,
                    a1=answer1,
                    a2=answer2,
                    a3=answer3,
                    a4=answer4
                )
        return redirect(url_for('index'))

    else:    
        return render_template('poll_create.html')

def get_poll(id):
    with db.connect() as conn:
        stmt = sqlalchemy.text(
            "SELECT * FROM polls p WHERE p.id = :id"
        )
        poll = conn.execute(
            stmt,
            id=id
        ).fetchone()

    if poll is None:
        abort(404, f"Poll id {id} doesn't exist.")

    return poll

@app.route('/poll/<int:index>', methods=['GET','POST'])
def poll_view(index):
    if request.method == 'POST':
        poll = get_poll(index)
        vote_name = request.form["vote"]
        
        stmt = sqlalchemy.text(
            "UPDATE polls SET " + str(vote_name) + " = " + str(vote_name) + " + 1 WHERE id = :id"
        )
        with db.connect() as conn:
            conn.execute(
                stmt,
                id=index
            )

        return redirect(url_for('poll_view', index=index))

    else:
        poll = get_poll(index)
    
        return render_template('poll_view.html', poll=poll)

@app.route('/poll-delete/<int:index>')
def poll_delete(index):
    stmt = sqlalchemy.text(
        "DELETE FROM polls WHERE id = :id"
    )
    with db.connect() as conn:
        conn.execute(
            stmt,
            id=str(index)
        )
    return redirect(url_for('index'))